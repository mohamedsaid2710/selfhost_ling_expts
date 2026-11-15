
.PHONY=start stop stopsilent test

# This Makefile is run from inside the experiment folder, because server.py
# serves the files of the directory it is started in.  server.py may sit in
# this folder (a single experiment folder uploaded on its own) or one level up
# (the whole repository); this folder wins if both exist.
SERVER := $(abspath $(firstword $(wildcard server.py ../server.py)))

# Interpreter: a uv venv (.venv, here or one level up) if it exists, otherwise
# whatever python3 is on PATH (e.g. apt's python3-bottle/-gevent on a server).
# It must be called by its venv path: resolving the symlink would drop the
# venv and with it bottle and gevent.
PYTHON3 := $(firstword $(abspath $(wildcard .venv/bin/python3 ../.venv/bin/python3)) $(shell which python3))

# setcap only works on the real binary, so resolve the symlink for that step.
PYTHON3_REAL := $(shell readlink -f $(PYTHON3))

# Allow binding port 80/443 without root; asks for sudo only the first time.
SETCAP = PATH="$$PATH:/usr/sbin:/sbin" getcap $(PYTHON3_REAL) | grep -q cap_net_bind_service || sudo setcap CAP_NET_BIND_SERVICE=+eip $(PYTHON3_REAL)

.SILENT:

start: stopsilent nohup.pid

nohup.pid: .SILENT
	test -n "$(SERVER)" || { echo "server.py not found (looked in this folder and one level up)."; exit 1; }
	$(SETCAP)
	nohup $(PYTHON3) $(SERVER) & echo $$! > $@;
	echo "Experiment started."

stopsilent:
	test -f nohup.pid && kill `cat nohup.pid` && rm nohup.pid || true

stop:
	test -f nohup.pid && kill `cat nohup.pid` && rm nohup.pid && echo "Experiment stopped." || echo "No experiment running."

test:
	test -n "$(SERVER)" || { echo "server.py not found (looked in this folder and one level up)."; exit 1; }
	$(SETCAP)
	$(PYTHON3) $(SERVER)
