#!/bin/bash
# Allows use of GPG keys stored in PGP smartcard for SSH

sshstart() {
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    gpg-connect-agent updatestartuptty /bye
}

sshstart >/dev/null
