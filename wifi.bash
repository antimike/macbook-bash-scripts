#!/bin/bash
# Convenience wrappers around NetworkManager and nmcli stuff

restart_wifi() {
    sudo systemctl restart NetworkManager
}
