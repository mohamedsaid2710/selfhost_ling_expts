
# Start, stop and test the experiment server.  Run from inside the experiment
# folder, because server.py serves the files of the directory it is started in.
#
#   make test    run in the foreground; Ctrl-C stops it
#   make start   run in the background (log: nohup.out, process id: nohup.pid)
#   make stop    stop the background server
#
# For data collection on a Linux server, instead of `make start`:
#
#   make install     run as a system service: started at boot and restarted
#                    if it ever stops (log: nohup.out)
#   make uninstall   stop the service and remove it

.PHONY: start stop test ready install uninstall

# server.py may sit in this folder (a single experiment folder uploaded on its
# own) or one level up (the whole repository); this folder wins if both exist.
SERVER := $(abspath $(firstword $(wildcard server.py ../server.py)))

# ---- Which Python runs the server -----------------------------------------
#
#   auto     (default) a .venv if there is one (here or one level up);
#            otherwise uv if it is installed; otherwise the system python3
#   uv       an environment managed by uv: the .venv if there is one,
#            otherwise uv creates one next to server.py with bottle and gevent
#   python3  the system python3, whatever else is installed
#            (e.g. with apt's python3-bottle and python3-gevent)
#
# Set your preference here, in the environment, or for one call:
#   make start RUNNER=python3
RUNNER ?= auto

ifeq ($(filter $(RUNNER),auto uv python3),)
  $(error RUNNER must be auto, uv or python3, not '$(RUNNER)')
endif

# The interpreter of a venv must be called by its venv path: resolving the
# symlink would drop the venv and with it bottle and gevent.
VENV_PYTHON   := $(firstword $(abspath $(wildcard .venv/bin/python3 ../.venv/bin/python3)))
SYSTEM_PYTHON := $(shell command -v python3 2>/dev/null)
UV            := $(shell command -v uv 2>/dev/null)
# Where uv creates the environment if there is none yet: next to server.py.
NEW_VENV      := $(abspath $(dir $(SERVER)).venv)

ifeq ($(RUNNER),python3)
  PYTHON3 := $(SYSTEM_PYTHON)
else ifneq ($(VENV_PYTHON),)
  PYTHON3 := $(VENV_PYTHON)
else ifneq ($(UV),)
  PYTHON3 := $(NEW_VENV)/bin/python3
  CREATE_VENV := yes
else ifeq ($(RUNNER),uv)
  $(error RUNNER=uv, but uv is not installed (or not on PATH))
else
  PYTHON3 := $(SYSTEM_PYTHON)
endif

# uv only provides the environment; the server itself is always started as
# "python3 server.py", so that nohup.pid holds the server's own process id.

# Allow binding port 80/443 without root; asks for sudo only the first time.
# setcap only works on the real binary, so the symlink is resolved for it.
SETCAP = real=$$(readlink -f $(PYTHON3)); PATH="$$PATH:/usr/sbin:/sbin"; \
  getcap "$$real" | grep -q cap_net_bind_service || sudo setcap CAP_NET_BIND_SERVICE=+eip "$$real"

# Stop the server named in nohup.pid -- but only if that process really is
# server.py.  After a reboot or a crash the file is left behind, and its
# number may by then belong to an unrelated process, which must not be killed.
# The file is removed either way.  Sets $stopped to yes or no.
STOP = stopped=no; \
  if [ -f nohup.pid ]; then \
    pid=$$(cat nohup.pid); \
    if [ -n "$$pid" ] && ps -p "$$pid" -o args= 2>/dev/null | grep -q 'server\.py'; then \
      kill "$$pid" && stopped=yes; \
    fi; \
    rm -f nohup.pid; \
  fi

# ---- System service (make install / make uninstall) -----------------------
#
# One fixed name, not one per experiment: only one server can listen on port
# 80/443, so installing a second experiment replaces the first instead of
# leaving two services fighting over the port.
SERVICE   := ling-experiment
UNIT_FILE := /etc/systemd/system/$(SERVICE).service

# The service runs as the user who installs it, from this folder, with the
# same Python and server.py as `make start`, and writes to the same log.
# AmbientCapabilities lets it bind port 80/443 without being root.
define UNIT
[Unit]
Description=Experiment server ($(CURDIR))
After=network-online.target
Wants=network-online.target

[Service]
User=$(shell id -un)
WorkingDirectory=$(CURDIR)
ExecStart="$(PYTHON3)" "$(SERVER)"
Restart=always
RestartSec=3
AmbientCapabilities=CAP_NET_BIND_SERVICE
Environment=PYTHONUNBUFFERED=1
StandardOutput=append:$(CURDIR)/nohup.out
StandardError=append:$(CURDIR)/nohup.out

[Install]
WantedBy=multi-user.target
endef
export UNIT

# True if the service is running (false on systems without systemd).
SERVICE_ACTIVE = command -v systemctl > /dev/null 2>&1 && systemctl is-active --quiet $(SERVICE)
# The experiment folder the service serves.
SERVICE_DIR = $$(systemctl show --property=WorkingDirectory --value $(SERVICE))
# `make start` and `make test` cannot run next to the service: the port is taken.
NO_SERVICE = if $(SERVICE_ACTIVE); then \
    echo "An experiment is already running as a system service, from $(SERVICE_DIR)."; \
    echo "Remove it first with: make uninstall"; exit 1; \
  fi

.SILENT:

# Everything that has to be in place before the server can run.
ready:
	test -n "$(SERVER)" || { echo "server.py not found (looked in this folder and one level up)."; exit 1; }
	test -n "$(PYTHON3)" || { echo "python3 not found."; exit 1; }
ifdef CREATE_VENV
	echo "Creating $(NEW_VENV) with uv (bottle, gevent) ..."
	uv venv --quiet "$(NEW_VENV)" && uv pip install --quiet --python "$(PYTHON3)" bottle gevent \
	  || { rm -rf "$(NEW_VENV)"; echo "Could not create the environment."; exit 1; }
endif
	$(SETCAP)

start: ready
	$(NO_SERVICE)
	$(STOP)
	nohup $(PYTHON3) $(SERVER) & echo $$! > nohup.pid
	# Give the server a moment, then check that it is still there (it exits
	# at once if, for example, the port is already in use).
	sleep 2
	kill -0 "`cat nohup.pid 2>/dev/null`" 2>/dev/null \
	  || { rm -f nohup.pid; echo "The server did not start; see nohup.out."; exit 1; }
	echo "Experiment started (Python: $(PYTHON3))."

stop:
	$(STOP); if [ "$$stopped" = yes ]; then echo "Experiment stopped."; \
	  elif $(SERVICE_ACTIVE); then echo "The experiment runs as a system service, from $(SERVICE_DIR); stop it with: make uninstall"; \
	  else echo "No experiment running."; fi

test: ready
	$(NO_SERVICE)
	echo "Python: $(PYTHON3)"
	$(PYTHON3) $(SERVER)

install: ready
	command -v systemctl > /dev/null 2>&1 || { echo "make install needs systemd (Linux). Use make start instead."; exit 1; }
	# A server started with `make start` would hold the port.
	$(STOP)
	printf '%s\n' "$$UNIT" | sudo tee $(UNIT_FILE) > /dev/null
	sudo systemctl daemon-reload
	sudo systemctl enable --quiet $(SERVICE)
	sudo systemctl restart $(SERVICE)
	sleep 2
	systemctl is-active --quiet $(SERVICE) \
	  || { echo "The service did not start; see nohup.out or: journalctl -u $(SERVICE)"; exit 1; }
	echo "Experiment installed as system service '$(SERVICE)' (Python: $(PYTHON3))."
	echo "It starts at boot and is restarted if it stops. Remove it with: make uninstall"

uninstall:
	if [ -f $(UNIT_FILE) ]; then \
	  dir=$(SERVICE_DIR); \
	  sudo systemctl disable --now --quiet $(SERVICE); \
	  sudo rm -f $(UNIT_FILE); \
	  sudo systemctl daemon-reload; \
	  echo "Service '$(SERVICE)' stopped and removed (it served $$dir)."; \
	else \
	  echo "No experiment is installed as a system service."; \
	fi
