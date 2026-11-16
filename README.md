
## What is this?

In this document, I explain how to set up and host browser-based experiments.  This approach uses [jsPsych](https://www.jspsych.org) for designing the experiment and a simple but effective Python script to serve it on the web.  This repository also includes demo experiments showing how standard (psycho)linguistic paradigms can be implemented.  Feel free to use these demos as templates for your own experiments.

## Terms of use

Use this guide and software at your own risk.  This guide, the script for serving the experiment online (`server.py`), and the `Makefile` are shared under the CC BY 4.0 license.  If you base your own research on these materials, please acknowledge it.

## Short instructions (for Linux, macOS)

Currently, the following demo experiments are available:
- [A super basic Stroop task, good starting point](https://github.com/tmalsburg/selfhost_ling_expts/tree/main/demo_stroop_task)
- [An acceptability judgment task](https://github.com/tmalsburg/selfhost_ling_expts/tree/main/demo_judgment_task)
- [A self-paced reading experiment for computers and phones, with three presentation modes](https://github.com/tmalsburg/selfhost_ling_expts/tree/main/demo_selfpacedreading)

To run the demo experiments (detailed instructions and explanations below):
1. Copy this repository to the server on which you’d like to run the experiment.
2. Install required software: `sudo apt install make python3-bottle python3-gevent`
3. In a command shell, enter the directory of the experiment that you’d like to test.
4. Execute `make test`.  The experiment will now be served at the address displayed in the shell.
5. Point your web browser to that address to test.
6. To stop the web server, press Ctrl-C in the shell.
7. Collected data can be found in the subdirectory `data`.

The instructions above are for testing.  For data collection, use `make install` on the server instead (see “Running an experiment for data collection” below).

## Overview

The sample experiments are implemented using [jsPsych](https://www.jspsych.org) which is one of the standard packages for implementing web-based experiments.  An alternative package that also looks promising is [lab.js](https://lab.js.org/).

[Bottle](https://bottlepy.org/docs/dev/) and [gevent](https://pypi.org/project/gevent/) are Python packages that we use to serve the experiment to the web and to store the results on the server.

- [Bottle](https://bottlepy.org/docs/dev/) is the Python web framework used for serving the experiment and storing the collected data.  Bottle was chosen because it is easy to use and well-documented.
- [gevent](https://pypi.org/project/gevent/) is our web server and handles network connections.  Gevent, too, is easy to use but at the same time it scales really well if needed.  It supports asynchronous processing and can simultaneously serve hundreds or even thousands of users.

The script `server.py` serves the experiment and stores the results in the subdirectory `data`.

Below are detailed instructions showing how to install and run the experiments.  You’ll need a virtual server running Ubuntu Linux (or similar).  Follow the instructions below for [DigitalOcean](https://www.digitalocean.com), a commercial cloud service provider.  People working at a university in Baden-Württemberg may try [bwCloud](bwCloud.md), a cloud service offered by the state.

## Create a virtual server (a “Droplet”) on DigitalOcean

1. Visit https://www.digitalocean.com and create an account.
2. Log in and visit the management interface at: https://cloud.digitalocean.com/projects
3. In the menu pane on the left select “Droplets”.
4. Click the blue button “Create Droplet”.
5. Configure Droplet:
   - Choose geographic region where the Droplet should be hosted (“Frankfurt”).
   - As operating system choose Ubuntu (latest version).
   - Select “Size” of Droplet.  “Shared CPU / Basic” plan is usually enough.
   - Under CPU options, choose “Regular”.  Scroll the horizontal list of available plans all the way to the left and choose the cheapest plan (USD 4, at the time of writing).
   - In the section “Choose Authentication Method”, you can choose “SSH Key” or “Password”.  The former is more secure and more convenient once it’s set up.  The latter is potentially insecure (depending on the password) but slightly easier to set up.  The “SSH Key” method is strongly recommended.  On Linux, the file containing your key can be found at: `~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`.  On macOS it’s probably in the same location.  No idea where it would be on Windows, but DigitalOcean shows some instructions for all operating systems when you click on the button “New SSH Key”.
   - The options that they offer in the next section are typically not needed.
   - In the section “Finalize Details” you can choose how many Droplets you want to create (usually 1) and give each a name.
   - Finally click the button “Create Droplet” at the bottom right.

## Install required software on the virtual server

1. Log into the virtual server using SSH in a terminal:
   - Copy the instance’s IP address from the list of instances (e.g., `193.196.54.221`).
   - Open a terminal and enter this command `ssh root@193.196.54.221` but with the actual IP address of your instance.  In this command, `root` is the default username used in DigitalOcean servers.  When using a bwCloud server, replace `root` with `ubuntu`.
   - SSH will warn you that the “authenticity of host XYZ can’t be established”.  That’s normal when you connect the first time.  Answer “yes” when asked whether you’d like to continue.
   - If all goes well, SSH will connect to the virtual server and show its command prompt, for instance, `root@test_instance:~$` on DigitalOcean or `ubuntu@test_instance:~$` on bwCloud.
2. Install required software packages: `sudo apt update && sudo apt install make python3-bottle python3-gevent r-cran-dplyr`

Done. You can now terminate the connection to the server by entering `exit`.  This will bring you back to the command prompt of your computer.

## Install the demo experiments on the virtual server

1. Connect to the virtual server: `ssh root@193.196.54.221`
2. To copy the demo experiments to the virtual server, simply clone its git repository: `git clone git@github.com:tmalsburg/selfhost_ling_expts.git`
3. Enter `ls selfhost_ling_expts` to see all files.  You should see:
   - `README.md`: the file you’re currently reading
   - `bwCloud.md`: instructions for setting up a virtual server on bwCloud
   - `server.py`: the script for serving the experiment and storing results on disk
   - `R`: R scripts for combining the result files and for analyzing the server’s log file
   - `demo_stroop_task`: directory containing the simple stroop task
   - `demo_judgment_task`: directory containing the simple judgment task
   - `demo_selfpacedreading`: directory containing the self-paced reading experiment
   - `demo_recaptcha`: directory containing a demo of how to add a reCAPTCHA

   Each experiment directory contains its own `Makefile` for starting and stopping the HTTP server that serves the experiment over the web.

## Run and test the stroop task

1. Enter the directory containing the experiment: `cd selfhost_ling_expts/demo_stroop_task`
2. To start the web server enter: `make start`
3. The server will use encrypted connections (`https://…`) if the directory contains a certificate and key (`cert.pem` and `key.pem`).  This will avoid messages shown in some browsers saying that the connection cannot be trusted.
4. You can now access the experiment in the browser at a URL like `http://193.196.54.221/` (unencrypted) or `https://193.196.54.221/` (encrypted) but using the IP address of your virtual server instance.
5. After you have worked through the experiment, you will find a new file in the subdirectory `data` named something like `results_1244af49-9db5-410f-92bb-e4ecef23fc61.csv`.  This file contains the results of your test run.  The part after `results_` is a so-called [UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) which is (for all practical purposes) globally unique.

## Stop the experiment

1. Enter the directory containing the experiment: `cd selfhost_ling_expts/demo_stroop_task`
2. To stop the server enter: `make stop`

## Running an experiment for data collection

A server started with `make start` runs until it is stopped, the machine reboots, or the process dies.  Cloud providers reboot their machines for maintenance from time to time, and the experiment would then be offline until someone logs in and starts it again.  For data collection, install the experiment as a system service instead:

1. Enter the directory containing the experiment: `cd selfhost_ling_expts/demo_stroop_task`
2. Enter: `make install`.  This asks for the `sudo` password.

The experiment is now started every time the machine boots, and restarted within a few seconds if the server ever stops.  Log messages go to `nohup.out` in the experiment directory, as with `make start`.

When data collection is over, enter `make uninstall` in the same directory to stop the experiment and remove the service.

On the server, `make install` and `make uninstall` therefore take the place of `make start` and `make stop`.  Which commands to use when:

| Situation | Start | Stop |
|---|---|---|
| Developing or piloting on your own computer | `make test` | Ctrl-C |
| The same, but in the background | `make start` | `make stop` |
| Data collection on the server | `make install` | `make uninstall` |

Do not use `make install` on your own computer: the experiment would start at every boot and stay reachable by anyone on the same network until it is uninstalled.

Things to know:

- This needs systemd, so it works on Linux (Ubuntu and similar) but not on macOS.
- Only one experiment can be installed at a time, because only one server can listen on port 80/443.  `make install` in another experiment directory replaces the experiment installed before.
- While an experiment is installed, `make start` and `make test` refuse to run and say why.
- Changes to the experiment's files (stimuli, `experiment.js`, …) take effect immediately.  After changing `server.py`, or which Python is used (see `RUNNER` below), run `make install` again.

## Compiling all individual result files into one file

The server stores one `results_<uuid>.csv` per participant and, for experiments with a questionnaire, one shared `survey.csv` with one row per participant.  To combine them, run from the top of the repository, e.g.:

```
Rscript R/combine_results.R demo_selfpacedreading/data
Rscript R/combine_results.R demo_judgment_task/data
```

This writes `combined.csv` into that data directory: all participants' rows stacked, with each participant's survey answers added to every one of their rows (matched by `participant_id`), and a column `source_file` naming the file each row came from.  Results files without a `participant_id` column (e.g. from the Stroop demo) get the random part of their file name as `participant_id`.  The script also prints the number of participants per Latin square list, and warns about files it could not read, participants without a survey row, and duplicate submissions.  It uses base R only, so nothing needs to be installed.  Rerun it whenever new data has come in; `combined.csv` is overwritten.

## Checking how often the experiment was opened

The server’s log file `nohup.out` records every request.  To see how often the experiment was opened, how often results were submitted, and how many of those who opened it also submitted results, run e.g.:

```
Rscript R/logfile_analysis.R demo_selfpacedreading/nohup.out
```

The numbers are approximate: participants are told apart by IP address only.  This script, too, uses base R only.

## Testing an experiment

For testing, use (which blocks the shell):
``` sh :eval no
make test
```
To stop the server, press Ctrl-C in the shell.

## Technical details

When starting the server with `make start`, the process id (PID) of the server will be stored in `nohup.pid` and log messages, including errors, in `nohup.out`.

The `Makefile` in each experiment directory starts `../server.py` from inside that directory, because the server serves the files of the directory it is started in.

`make stop` (and the restart done by `make start`) only stops the process named in `nohup.pid` if it really is `server.py`.  After a reboot or a crash that file is left behind, and its number may by then belong to another process.  `make start` also checks after two seconds that the server is still running and says so if it is not (for instance because the port is in use).

The `Makefile` chooses the Python that runs the server:

- `auto` (the default): a `.venv` in the experiment directory or one level up if there is one; otherwise [uv](https://docs.astral.sh/uv/) if it is installed; otherwise the system `python3`.
- `uv`: an environment managed by uv.  If there is no `.venv` yet, uv creates one next to `server.py` and installs `bottle` and `gevent` into it, so nothing has to be installed with `apt`.
- `python3`: the system `python3` (with `python3-bottle` and `python3-gevent` from `apt`), whatever else is installed.

To state a preference, change `RUNNER ?= auto` at the top of the `Makefile`, set the environment variable `RUNNER`, or give it for one call: `make start RUNNER=python3`.  `make start`, `make test` and `make install` print which Python they use.

`make install` writes the service to `/etc/systemd/system/ling-experiment.service`.  The service runs as the user who installed it, from the experiment directory, with the same Python and the same `server.py` as `make start`.  Its state can be checked with `systemctl status ling-experiment`.

The server listens on port 80 (or 443 with `cert.pem` and `key.pem`), which normally requires root privileges.  Instead of running the server as root, `make start` and `make test` give the Python interpreter permission to use these ports (`sudo setcap CAP_NET_BIND_SERVICE=+eip …`).  This is done only once, which is why the password is requested only the first time.

## Acknowledgements

Thanks go to Judith Tonhauser, who provided useful comments and suggestions and helped test some of the software in this repository.
