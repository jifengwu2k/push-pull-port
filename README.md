# Port Tunnel Manager

Bash scripts to make a local port available on a remote host or make a remote port available locally via `autossh`.

## Prerequisites

Before using these scripts, ensure the following:

- `autossh` Installation
    - Both scripts require [autossh](https://www.harding.motd.ca/autossh/) on the **local machine** for robust, auto-reconnecting tunnels.
    - Install on Ubuntu:  
      `sudo apt install autossh`
    - Install on MacOS:  
      `brew install autossh`
- GatewayPorts
   - When using `push_local_port.sh`, to make the port pushed to the **remote host** accessible from other hosts:
      - Set the following in `/etc/ssh/sshd_config` on the **remote host**:
         - `GatewayPorts yes`
      - Then **restart** `sshd` on the remote host.
- SSH Keys
    - For unattended tunnels, you should set up SSH key-based authentication so you're not prompted for a password on every reconnect.
    - On your **local machine**:
      - Generate an SSH key pair (if you don't already have one):
         - `ssh-keygen` (just press Enter all the way through)
      - Copy your public key to the remote host:
         - `ssh-copy-id [-p <ssh_port>] <user>@<host>`

## `push_local_port.sh`

Makes a local port available on a remote host (e.g. expose local dev server on cloud gateway)

### When to Use

When you need to:

- Expose a local web server to the Internet
- Share local development environment

### Usage

```
bash push_local_port.sh [-p <ssh_port>] -l <local_port> -u <user> -h <host> -r <remote_port>
```

- The optional `-p <ssh_port>` lets you specify a custom SSH port (default is 22).

### Example

```bash
# SSH into dev@dev.example.com and make local port 3000 available on dev.example.com:3001
bash push_local_port.sh -l 3000 -u dev -h dev.example.com -r 3001

# If SSH is running on port 2222:
bash push_local_port.sh -p 2222 -l 3000 -u dev -h dev.example.com -r 3001
```

## `pull_remote_port.sh`

Makes a remote port available locally (e.g. access private database through local port)

### When to Use

When you need to:

- Connect to private databases
- Access internal APIs
- Secure sensitive service connections

### Usage

```
bash pull_remote_port.sh [-p <ssh_port>] -u <user> -h <host> -r <remote_port> -l <local_port>
```

- The optional `-p <ssh_port>` lets you specify a custom SSH port (default is 22).

### Example

```bash
# SSH into admin@db.internal and make db.internal:3306 accessible through localhost:3307
bash pull_remote_port.sh -u admin -h db.internal -r 3306 -l 3307

# If SSH is running on port 2222:
bash pull_remote_port.sh -p 2222 -u admin -h db.internal -r 3306 -l 3307
```

## Why We Use Push/Pull Instead of Forward/Reverse

### The Problem with Traditional 

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

| User Goal                  | Traditional Term       | Our Term | SSH Option |
|----------------------------|------------------------|----------|------------|
| Make local service available on remote host | Remote Forwarding | **Push** | `ssh -R` |
| Access remote service through local port    | Local Forwarding  | **Pull** | `ssh -L` |

### Key Advantages

1. **Intent-Oriented**  
   - `push_local_port.sh`: "I want to make this local port available there"  
   - `pull_remote_port.sh`: "I want to access that remote port here"

2. **Directionally Clear**  
   Eliminates ambiguity about "whose local/remote" we're referring to.

3. **Cloud-Native Alignment**  
   Matches modern service mesh concepts (ingress/egress) better than SSH's 1990s perspective.

### Technical Implementation

While we use human-friendly terms, the underlying technology remains standard SSH:

```bash
# push_local_port.sh uses ssh -R (traditional "remote forwarding")
# pull_remote_port.sh uses ssh -L (traditional "local forwarding")
```

This terminology choice reflects our belief that tools should describe what users want to accomplish, not how the protocol implements it.