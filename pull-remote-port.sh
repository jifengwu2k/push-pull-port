#!/bin/sh

verify_deps() {
    if ! command -v autossh >/dev/null; then
        echo "Missing required tool: autossh"
        echo "Install with:"
        echo "  Ubuntu: sudo apt install autossh"
        echo "  MacOS: brew install autossh"
        exit 1
    fi
}

show_help() {
    echo "Usage: $0 -r <remote_port> [-p <ssh_port>] -u <user> -h <host> -l <local_port>" >&2
    echo "Pull localhost:<remote_port> on 'ssh -p <ssh_port> <user>@<host>' to localhost:<local_port> on your machine." >&2
    exit 1
}

# Parse arguments
while getopts "r:p:u:h:l:" opt; do
    case "$opt" in
        r) REMOTE_PORT="$OPTARG" ;;
        p) SSH_PORT="$OPTARG" ;;
        u) USER="$OPTARG" ;;
        h) HOST="$OPTARG" ;;
        l) LOCAL_PORT="$OPTARG" ;;
        *) show_help ;;
    esac
done

# Validate
verify_deps

if [ -z "$REMOTE_PORT" ] || [ -z "$USER" ] || [ -z "$HOST" ] || [ -z "$LOCAL_PORT" ]
then
    show_help
fi

if [ -z "$SSH_PORT" ]
then
    SSH_PORT=22
fi

# Infinite loop: repeatedly launch autossh, wait for it to exit, pause, and restart
while true
do
    # Start autossh in background with given tunnel args
    autossh -M 0 \
        -o "ServerAliveInterval 30" \
        -o "ServerAliveCountMax 3" \
        -o "ExitOnForwardFailure=yes" \
        -N -L "${LOCAL_PORT}:localhost:${REMOTE_PORT}" \
        -p "${SSH_PORT}" \
        "${USER}@${HOST}" &
    autossh_pid="$!"
    echo "Pulling localhost:${REMOTE_PORT} on 'ssh -p ${SSH_PORT} ${USER}@${HOST}' to localhost:${LOCAL_PORT} on your machine (Press Ctrl+C to stop)"

    # Wait for autossh to exit (either gracefully or due to error)
    wait "$autossh_pid"

    # Inform the user and pause before retrying
    echo "autossh exited. Sleeping for 10 seconds before reconnecting..."
    sleep 10
done
