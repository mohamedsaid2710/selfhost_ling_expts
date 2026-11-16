
# Summarize the server's log file: how often the experiment was opened and
# how often results were submitted.
#
# Usage, from the top of the repository:
#
#   Rscript R/logfile_analysis.R demo_selfpacedreading/nohup.out
#
# or from inside an experiment's directory:  Rscript ../R/logfile_analysis.R
# (the log file defaults to ./nohup.out).
#
# Base R only, so it runs on any machine with R and nothing to install.
#
# Be advised that the log file's structure is messy due to its
# inconsistent format and potential disruptions from hacking attempts.
# The analyses below are provided with an understanding of these
# uncertainties and should not be interpreted as precise.

args <- commandArgs(trailingOnly = TRUE)
log_path <- if (length(args) >= 1) args[1] else "nohup.out"
if (!file.exists(log_path)) stop("No log file '", log_path, "'.")

# Keep only lines in the standard access log format, e.g.
#
#   203.0.113.7 - - [2026-11-16 10:26:44] "GET / HTTP/1.1" 200 1498 0.002282
#
# This removes the server's own messages and obvious hacking attempts
# (which do not follow that format).
lines <- readLines(log_path, warn = FALSE, encoding = "UTF-8")
lines <- iconv(lines, "UTF-8", "UTF-8", sub = "?")
pattern <- '^(\\S+) - - \\[([^]]+)\\] "([^"]*)" ([0-9]{3}) (\\S+) (\\S+)$'
access <- lines[grepl(pattern, lines)]
if (length(access) == 0) stop("No access log lines in '", log_path, "'.")

d <- data.frame(
  IP       = sub(pattern, "\\1", access),
  datetime = as.POSIXct(sub(pattern, "\\2", access), format = "%Y-%m-%d %H:%M:%S"),
  request  = sub(pattern, "\\3", access),
  code     = sub(pattern, "\\4", access),
  stringsAsFactors = FALSE)

message(length(access), " of ", length(lines), " lines are access log lines, from ",
        format(min(d$datetime, na.rm = TRUE)), " to ", format(max(d$datetime, na.rm = TRUE)), ".")

# Tally of HTTP response codes:
message("\nHTTP response codes:")
print(table(code = d$code))

# How many times was the experiment requested?  Counting successful requests
# for the start page.  The server marks every response as uncacheable, so
# each time a participant opens or reloads the experiment is counted.
ok <- d$code == "200"
d.loads <- d[ok & grepl("^GET / ", d$request), ]
message("\nExperiment opened: ", nrow(d.loads), " time(s), from ",
        length(unique(d.loads$IP)), " IP address(es).")

# How many times were results submitted for storage?  Counting successful
# requests to /store; the questionnaire (kind=survey) is sent separately and
# is not counted a second time.
d.store <- d[ok & grepl("^POST /store", d$request) & !grepl("kind=survey", d$request), ]
message("Results submitted: ", nrow(d.store), " time(s), from ",
        length(unique(d.store$IP)), " IP address(es).")

# IP addresses that opened the experiment multiple times.  Some do so within
# a short interval (perhaps trying a different browser), some at larger
# intervals up to multiple days.
repeated <- d.loads[duplicated(d.loads$IP) | duplicated(d.loads$IP, fromLast = TRUE), ]
if (nrow(repeated) > 0) {
  message("\nIP addresses that opened the experiment more than once:")
  print(repeated[order(repeated$IP, repeated$datetime), c("IP", "datetime")], row.names = FALSE)
}

# How many of those who opened the experiment submitted results?  We're
# assuming that each participant has a unique IP address and participated
# only once.  (We can't distinguish multiple clients who're using the same
# IP.)
opened <- unique(d.loads$IP)
message("\nOf the IP addresses that opened the experiment, how many submitted results:")
print(table(stored_data = opened %in% d.store$IP))
