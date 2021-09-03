#!/bin/bash
# Allows use of GPG keys stored in PGP smartcard for SSH

export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
gpg-connect-agent updatestartuptty /bye

alias sshstart="source '${BASH_SOURCE[0]}'"
