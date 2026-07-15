#!/bin/bash
# ===========================================================================
# This script sends ah HTTP request from a custom host on a user-defined port
# over Netcat, and therefore emulates a basic HTTP client.
# NOTE: one-liners for the server and client replacing this structured script
#       may look like this:
#       # Server
#       printf "HTTP/1.1 200 OK\r\nContent-type: text/plain\r\nContent-Length: 12\r\nConnection: close\r\n\r\nHello World\n" | nc -l 8080
#       # Client
#       printf "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 8080
# ===========================================================================

set -euo pipefail

# -----------------------
# User-defined parameters
# -----------------------
HOST="localhost"
PORT=8080


# -------------
# HTTP requests
# -------------
# 1. Get server status
awk '{print $0 "\r"}' <<- EOF | nc -v "$HOST" $PORT
GET /status HTTP/1.1
Host: $HOST:$PORT
User-Agent: BashClient/1.0
Accept: text/plain
Connection: close

EOF
sleep 3


# 2. Get server time
awk '{print $0 "\r"}' <<- EOF | nc -v "$HOST" $PORT
GET /time HTTP/1.1
Host: $HOST:$PORT
User-Agent: BashClient/1.0
Accept: text/plain
Connection: close

EOF
sleep 3


# 3. Send invalid request (wrong command) 
awk '{print $0 "\r"}' <<- EOF | nc -v "$HOST" $PORT
WRONG_COMMAND /status HTTP/1.1
Host: $HOST:$PORT
User-Agent: BashClient/1.0
Accept: text/plain
Connection: close

EOF
sleep 3


# 4. Send invalid request (no Host field) 
awk '{print $0 "\r"}' <<- EOF | nc -v "$HOST" $PORT
WRONG_COMMAND /status HTTP/1.1
User-Agent: BashClient/1.0
Accept: text/plain
Connection: close

EOF
