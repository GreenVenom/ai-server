#!/bin/bash

set -e

mkdir -p ~/.ssh
chmod 700 ~/.ssh

cat >> ~/.ssh/authorized_keys

chmod 600 ~/.ssh/authorized_keys