#!/bin/bash

# ==========================================
# Modular Osquery Installer
# Supported OS: Ubuntu (Implemented), rocky/CentOS (Placeholder)
# ==========================================

# Global Variables
OSQUERY_KEYRING="/usr/share/keyrings/osquery-archive-keyring.gpg"

# Helper Function: Check Root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root or use sudo."
        exit 1
    fi
}

# ------------------------------------------
# Function: Install on Ubuntu/Debian
# ------------------------------------------
install_ubuntu() {
    echo "[+] Detected Ubuntu/Debian system."
    
    echo "[+] Updating apt and installing dependencies..."
    apt-get update -y
    apt-get install -y software-properties-common curl gnupg

    echo "[+] Importing Osquery GPG key..."
    # Download key, dearmor it, and place it in the secure keyring location
    curl -L https://pkg.osquery.io/deb/osquery.gpg | gpg --dearmor -o "$OSQUERY_KEYRING" --yes

    echo "[+] Adding Osquery repository..."
    echo "deb [arch=amd64 signed-by=$OSQUERY_KEYRING] https://pkg.osquery.io/deb deb main" | tee /etc/apt/sources.list.d/osquery.list

    echo "[+] Updating package lists..."
    apt-get update -y

    echo "[+] Installing Osquery..."
    apt-get install -y osquery
}

# ------------------------------------------
# Function: Install on Rocky/CentOS (Placeholder)
# ------------------------------------------
install_rocky() {
    echo "[+] Detected Rocky/CentOS system."
    echo "[-] TODO: Add Rocky installation logic here."
    # Example logic for future use:
    # yum install yum-utils
    # yum -ivh https://pkg.osquery.io/rpm/osquery-repo-1-0.0.x86_64.rpm
    # yum install osquery
}

# ------------------------------------------
# Main Execution Logic
# ------------------------------------------

check_root

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    DISTRO_ID=$ID
else
    echo "ERROR: Cannot detect OS. /etc/os-release not found."
    exit 1
fi

echo "Detected OS: $OS"

case "$DISTRO_ID" in
    ubuntu|debian)
        install_ubuntu
        ;;
    centos|rocky|fedora)
        install_rocky
        ;;
    *)
        echo "ERROR: Unsupported Operating System: $DISTRO_ID"
        exit 1
        ;;
esac

# ------------------------------------------
# Post-Installation (Common)
# ------------------------------------------

echo "[+] Enabling and starting osqueryd service..."
systemctl enable osqueryd
systemctl start osqueryd

if systemctl is-active --quiet osqueryd; then
    echo "------------------------------------------------"
    echo "SUCCESS: osqueryd is installed and running!"
    echo "Version installed:"
    osqueryi --version
    echo "------------------------------------------------"
else
    echo "ERROR: osqueryd failed to start. Please check logs."
    exit 1
fi