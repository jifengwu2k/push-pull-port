#!/bin/bash
# Makes a local port available on a remote host (e.g. expose local dev server on cloud gateway)


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
    echo "Makes a local port available on a remote host:"
    echo "  $0 [-p <ssh_port>] -l <local_port> -u <user> -h <host> -r <remote_port>"
    echo "Example (SSH into dev@dev.example.com and make local port 3000 available on dev.example.com:3001):"
    echo "  $0 -l 3000 -u dev -h dev.example.com -r 3001"
    exit 1
}

# Parse arguments
while getopts "p:l:u:h:r:" opt; do
    case "$opt" in
        p) SSH_PORT="$OPTARG" ;;
        l) LOCAL_PORT="$OPTARG" ;;
        u) USER="$OPTARG" ;;
        h) HOST="$OPTARG" ;;
        r) REMOTE_PORT="$OPTARG" ;;
        *) show_help ;;
    esac
done

# Validate
verify_deps

[[ -z "$LOCAL_PORT" || -z "$USER" || -z "$HOST" || -z "$REMOTE_PORT" ]] && show_help

if [[ -z "$SSH_PORT" ]]; then
    SSH_PORT=22
fi

# Main loop
echo "Pushing local port $LOCAL_PORT to $HOST:$REMOTE_PORT (Press Ctrl+C to stop)"

autossh -M 0 \
    -o "ServerAliveInterval 30" \
    -o "ServerAliveCountMax 3" \
    -N -R "${REMOTE_PORT}:localhost:${LOCAL_PORT}" \
    -p "${SSH_PORT}" \
    "${USER}@${HOST}"