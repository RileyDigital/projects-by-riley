#!/bin/bash

# Setup backup output directory and timestamp
TIMESTAMP=$(date +%F_%T)
BACKUP_DIR="/home/admin/backups/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

echo "Starting full backup..."

# SSH Server: authorized_keys from all users

echo "Backing up authorized_keys from SSH server..."
mkdir -p "$BACKUP_DIR/ssh-server/riley"
mkdir -p "$BACKUP_DIR/ssh-server/sarah"
mkdir -p "$BACKUP_DIR/ssh-server/admin"

scp riley@192.168.100.4:/home/riley/.ssh/authorized_keys "$BACKUP_DIR/ssh-server/riley/authorized_keys"
scp sarah@192.168.100.4:/home/sarah/.ssh/authorized_keys "$BACKUP_SIR/ssh-server/sarah/authorized_keys"
scp admin@192.168.100.4:/home/admin/.ssh/authorized_keys "$BACKUP_DIR/ssh-server/admin/authorized_keys"

# Git Server: all repositories
echo "Backing up git repositories..."

mkdir -p "$BACKUP_DIR/git"
scp -r admin@192.168.100.5:/car/git-repo/* "$BACKUP_DIR/git/"

# Web Server: Apache/DokuWiki content
echo "Backing up web server data..."

mkdir "$BACKUP_DIR/web"
scp -r admin@192.168.100.3:/var/www/html/* "$BACKUP_DIR/web/"

# Clients: private SSH keys
echo "Backing up client private SSH keys..."
mkdir -p "$BACKUP_DIR/clients/riley"
mkdir -p "$BACKUP_DIR/clients/sarah"

scp riley@192.168.100.100:/home/riley/.ssh/id_ed25519 "$BACKUP_DIR/clients/riley/id_ed25519"
scp sarah@192.168.100.150:/home/sarah/.ssh/id_ed25519 "$BACKUP_DIR/clients/sarah/id_ed25519"

# Permissions
chmod -R 700 "$BACKUP_DIR"

echo "Backup complete. Files saved to $BACKUP_DIR