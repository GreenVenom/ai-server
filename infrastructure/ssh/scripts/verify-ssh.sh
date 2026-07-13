#!/bin/bash

echo "SSH Status"

echo
echo "Authorized Keys:"
ls -la ~/.ssh

echo
echo "SSH Daemon:"
sudo launchctl print system/com.openssh.sshd

echo
echo "Configuration Check:"
sudo sshd -t