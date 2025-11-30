# `push-pull-port`

Dead simple, jargon-free Shell scripts to make a local TCP port available on a remote host or make a remote TCP port available locally.

## Motivation

**Modern work is mobile.** Whether you're at home, in a cafe, or on the move with 4G, you need secure, on-demand access to your devices and services - without wrestling with complex forwarding rules or VPNs.

`push-pull-port` lets you instantly "push" or "pull" any TCP port via SSH with human-friendly commands.

- Expose your device's SSH, VNC, or web apps at a moment's notice.
- Stop and start tunnels with a single command.
- Failures show up *immediately* - no silent, sneaky background errors.

**It's the Unix philosophy, everywhere:** portable, composable, and under your control.

## Prerequisites

Before using these scripts, ensure the following:

- On the Local Machine:
   - `autossh` Installation
      - Both scripts require [autossh](https://www.harding.motd.ca/autossh/) for robust, auto-reconnecting tunnels.
      - Install on Ubuntu:  
         `sudo apt install autossh`
      - Install on MacOS:  
         `brew install autossh`
   - SSH Keys
      - For unattended tunnels, you should set up SSH key-based authentication so you're not prompted for a password on every reconnect.
      - Generate an SSH key pair (if you don't already have one):
         - `ssh-keygen` (just press Enter all the way through)
      - Copy your public key to the remote host:
         - `ssh-copy-id [-p <ssh_port>] <user>@<host>`
- On the Remote Host:
   - Have `sshd` running (no-brainer).
   - GatewayPorts 
      - When using `push-local-port.sh`, to make the pushed port accessible from other hosts:
         - Set the following in `/etc/ssh/sshd_config`:
            - `GatewayPorts clientspecified`
         - Then restart `sshd` on the remote host.

## `push-local-port.sh`

Push `localhost:<local_port>` on your machine to `<remote_port>` on `ssh -p <ssh_port> <user>@<host>`.

### When to Use

When you need to:

- Expose a local web server to the Internet
- Share local development environment

### Usage

```
sh push-local-port.sh -l <local_port> -r <remote_port> [-p <ssh_port>] -u <user> -h <host> [-x]
```

> The optional `-p <ssh_port>` lets you specify a custom SSH port (default is 22).
> 
> `-x` opens the remote port on localhost only. Use this if you want the forwarded port accessible only from the host itself, not the network.

### Example

```bash
# Make local port 3000 available on dev.example.com:3001 by SSHing into dev@dev.example.com
sh push-local-port.sh -l 3000 -r 3001 -u dev -h dev.example.com

# If SSH is running on port 2222:
sh push-local-port.sh -l 3000 -r 3001 -p 2222 -u dev -h dev.example.com 

# Only allow access from the host's own localhost:
sh push-local-port.sh -l 3000 -r 3001 -p 2222 -u dev -h dev.example.com -x
```

## `pull-remote-port.sh`

Pull `localhost:<remote_port>` on `ssh -p <ssh_port> <user>@<host>` to `localhost:<local_port>` on your machine.

### When to Use

When you need to:

- Connect to private databases
- Access internal APIs
- Secure sensitive service connections

### Usage

```
sh pull-remote-port.sh -r <remote_port> [-p <ssh_port>] -u <user> -h <host> -l <local_port>
```

> The optional `-p <ssh_port>` lets you specify a custom SSH port (default is 22).

### Example

```bash
# SSH into admin@db.internal and make db.internal:3306 accessible through localhost:3307
sh pull-remote-port.sh -r 3306 -u admin -h db.internal -l 3307

# If SSH is running on port 2222:
sh pull-remote-port.sh -r 3306 -p 2222 -u admin -h db.internal -l 3307
```

## Foreground Operation: Visibility Over Stealth

We intentionally run all tunnels in the **foreground**. This ensures:

- **Immediate Error Visibility:** Any connection issues, authentication failures, or port conflicts are clearly printed to your terminal, so you can respond and debug without guessing.
- **No Silent Failures:** By avoiding background daemons, you won't miss subtle (or catastrophic) tunnel dropouts that go unnoticed.
- **Stopping the tunnel:** Simply press `Ctrl-C` to stop the tunnel. You can also close the terminal window/tab to end it.

> Tip: If you ever want to run the tunnel in the background, you can use a terminal multiplexer like `tmux` to keep tunnels running while detached.

## Why We Use Push/Pull Instead of Forward/Reverse

### The Problem with Traditional Terms

The standard SSH port forwarding terms (`local forwarding` vs `remote forwarding`) are notoriously confusing because:

1. **Perspective Dependence**  
   The "remote" and "local" labels depend on which machine initiates the SSH connection, not the actual service exposure direction users care about.

2. **Cognitive Mismatch**  
   When developers want to:
   - **Expose a local service** remotely, they must remember this is called "remote forwarding" (`-R`)
   - **Access a remote service** locally, this is called "local forwarding" (`-L`)

3. **Implementation-First Naming**  
   The terms describe SSH's technical implementation rather than user intent.

### Our Push/Pull Metaphor

We intentionally avoid `forward/reverse` terminology in favor of intuitive action verbs:

| User Goal                                 | Traditional Term    | Our Term | SSH Option |
|--------------------------------------------|---------------------|----------|------------|
| Make local service available on remote host| Remote Forwarding   | Push     | `ssh -R`   |
| Access remote service through local port   | Local Forwarding    | Pull     | `ssh -L`   |

### Key Advantages

1. **Intent-Oriented**  
   - `push-local-port.sh`: "I want to make this local port available there"  
   - `pull-remote-port.sh`: "I want to access that remote port here"

2. **Directionally Clear**  
   Eliminates ambiguity about "whose local/remote" we're referring to.

3. **Cloud-Native Alignment**  
   Matches modern service mesh concepts (ingress/egress) better than SSH's 1990s perspective.

### Technical Implementation

While we use human-friendly terms, the underlying technology remains standard SSH:

```bash
# push-local-port.sh uses ssh -R (traditional "remote forwarding")
# pull-remote-port.sh uses ssh -L (traditional "local forwarding")
```

This terminology choice reflects our belief that tools should describe what users want to accomplish, not how the protocol implements it.