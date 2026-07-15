#!/bin/bash
# ===========================================================================
# This script sends an HTTP response with a custom plain text content over a
# user-defined port over Netcat, and therefore emulates a basic HTTP server.
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
PORT=8080


# -----
# Begin
# -----
# Build a FIFO object to handle two-way communication via Netcat
TMP_FIFO="/tmp/http_server_fifo"
rm -f "$TMP_FIFO"
mkfifo "$TMP_FIFO"

REQUEST_LINE_REGEX='^[A-Z]+ [^[:space:]]+ HTTP/[123](\.[01])?$'
HOST_REGEX='^Host: [^[:space:]]+$'


while true
do
    # Logic breakdown
    # 1. nc -l -q 1 $PORT < "$TMP_FIFO"
    #    Feed data from the temporary FIFO into Netcat. Since the FIFO content
    #    is Netcat's STDIN here, that's what will appear on the client's
    #    terminal.
    #    NOTE: `-q 1` makes Netcat wait one second after seeing EOF before
    #          closing the connection (works with OpenBSD's Netcat only)
    # 2. | { # Parsing block }
    #    Pipe Netcat's STDOUT (the client's request) into the parsing block below
    # 3. { # Parsing block } > "$TMP_FIFO"
    #    The parsing block's output is redirected back into the FIFO and the
    #    cycle starts over again
    nc -l -q 1 -v $PORT < "$TMP_FIFO" | {
        REQUEST_LINE=""
        REQUEST_CONTAINS_HOST=false
        STATUS="200 OK"
        BODY=""

        # -------------------------------
        # Parse the client's HTTP request
        # -------------------------------
        while IFS= read -r line
        do
            # Clean hidden carriage returns
            line="${line%$'\r'}"

            # A blank line marks the end of the HTTP request's header
            if [ -z "$line" ]
            then
                break
            fi

            # Capture the very first line (request line)
            if [ -z "$REQUEST_LINE" ]
            then 
                REQUEST_LINE="$line"

                # Make sure the request line has the right format
                # Example: "GET /status HTTP/1.1"
                if ! [[ "$REQUEST_LINE" =~ $REQUEST_LINE_REGEX ]]
                then 
                    STATUS="400 Bad Request"
                    BODY="Error: missing or malformed request from client"
                fi
            fi

            # Make sure "Host:" is there in the client's request
            # NOTE: "[^[:space:]]+" matches any number of characters that is NOT any
            #       type of blank space (including literal blank spaces, tabs, newlines,
            #       carriage returns)
            if [[ $line =~ $HOST_REGEX ]]
            then
                REQUEST_CONTAINS_HOST=true
            fi
        done

        # ----------------------
        # Send the HTTP response
        # ----------------------
        if $REQUEST_CONTAINS_HOST
        then
            # Extract the HTTP method (e.g., GET, POST, etc.) and path (e.g., "/" or
            # "/status")
            METHOD=$(  echo "$REQUEST_LINE" | awk '{print $1}')
            PATH_URL=$(echo "$REQUEST_LINE" | awk '{print $2}')  # DO NOT overwrite the system's $PATH

            case "$METHOD:$PATH_URL" in
                GET:/status)
                    BODY="Server status: ok"
                    ;;
                GET:/time)
                    BODY="Server date and time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
                    ;;
                *)
                    STATUS="404 Not Found"
                    BODY="ERROR: requested path URL not found on server"
                    ;;
            esac
        else
            STATUS="400 Bad Request"
            BODY="ERROR: Client provided no Host in their request"
        fi


        # ***** Actually send out the HTTP response *****

        # Use printf instead of echo to avoid appending a trailing newline character
        BODY_LENGTH=$(printf '%s' "$BODY" | wc -c)  # Use printf instead of echo to avoid appending a trailing newline character
        
        # - HTTP header lines must end with "\r\n" (carriage-return plus line feed or
        #   CRLF). The command
        #     awk '{print $0 "\r"}' "my string"
        #   converts "my string" to "my string\r\n" ("\n" is added by printf
        #   automatically).
        # - Wrapping the nc command in an infinite while loop ensures nc keeps on
        #   listening for incoming requests after the first one has been processed
        # - "<<-" ignores indentation in the here-doc
        awk '{print $0 "\r"}' <<- EOF
HTTP/1.1 $STATUS
Content-type: text/plain
Content-length: $BODY_LENGTH
Connection: close

$BODY
EOF
    } > "$TMP_FIFO"
done

# Remove the FIFO in case of regular exit, interruption, or termination
trap 'rm -f "$TMP_FIFO"' EXIT INT TERM
