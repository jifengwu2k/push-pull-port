#!/bin/bash
# Makes a remote port available locally (e.g. access private database through local port)


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
    echo "Makes a remote port available locally:"
    echo "  $0 [-p <ssh_port>] -u <user> -h <host> -r <remote_port> -l <local_port>"
    echo "Example (SSH into admin@db.internal and make db.internal:3306 accessible through localhost:3307):"
    echo "  $0 -u admin -h db.internal -r 3306 -l 3307"
    exit 1
}

# Parse arguments
while getopts "p:u:h:r:l:" opt; do
    case "$opt" in
        p) SSH_PORT="$OPTARG" ;;
        u) USER="$OPTARG" ;;
        h) HOST="$OPTARG" ;;
        r) REMOTE_PORT="$OPTARG" ;;
        l) LOCAL_PORT="$OPTARG" ;;
        *) show_help ;;
    esac
done

# Validate
verify_deps

[[ -z "$USER" || -z "$HOST" || -z "$REMOTE_PORT" || -z "$LOCAL_PORT" ]] && show_help

if [[ -z "$SSH_PORT" ]]; then
    SSH_PORT=22
fi

# Main loop
echo "Pulling $HOST:$REMOTE_PORT to local port $LOCAL_PORT (Press Ctrl+C to stop)"

autossh -M 0 \
    -o "ServerAliveInterval 30" \
    -o "ServerAliveCountMax 3" \
    -N -L "${LOCAL_PORT}:localhost:${REMOTE_PORT}" \
    -p "${SSH_PORT}" \
    "${USER}@${HOST}"