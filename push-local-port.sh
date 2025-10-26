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
    echo "Usage: $0 -l <local_port> -r <remote_port> [-p <ssh_port>] -u <user> -h <host>" >&2
    echo "Push localhost:<local_port> on your machine to <remote_port> on 'ssh -p <ssh_port> <user>@<host>'" >&2
    exit 1
}

# Parse arguments
while getopts "l:r:p:u:h:" opt; do
    case "$opt" in
        l) LOCAL_PORT="$OPTARG" ;;
        r) REMOTE_PORT="$OPTARG" ;;
        p) SSH_PORT="$OPTARG" ;;
        u) USER="$OPTARG" ;;
        h) HOST="$OPTARG" ;;
        *) show_help ;;
    esac
done

# Validate
verify_deps

if [ -z "$LOCAL_PORT" ] || [ -z "$REMOTE_PORT" ] || [ -z "$USER" ] || [ -z "$HOST" ]
then
    show_help
fi

if [ -z "$SSH_PORT" ]; then
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
        -N -R "${REMOTE_PORT}:localhost:${LOCAL_PORT}" \
        -p "${SSH_PORT}" \
        "${USER}@${HOST}" &
    autossh_pid="$!"
    echo "Pushing localhost:${LOCAL_PORT} on your machine to ${REMOTE_PORT} on 'ssh -p ${SSH_PORT} ${USER}@${HOST} (Press Ctrl+C to stop)"

    # Wait for autossh to exit (either gracefully or due to error)
    wait "$autossh_pid"

    # Inform the user and pause before retrying
    echo "autossh exited. Sleeping for 10 seconds before reconnecting..."
    sleep 10
done
