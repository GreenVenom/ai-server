---
title: Enable Remote Login
document: Reference
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: GreenVenom
---

# Enable Remote Login

Enable remote login on macOS to allow SSH access to your machine. This can be done through the System Settings or via the command line.

## System Settings

1. Open System Preferences.
2. Click on "Users & Groups".
3. Click on "Login Options".
4. Click on "Remote Login".
5. Click "Enable Remote Login".

## Command Line

1. Open Terminal.
2. Run the command `sudo systemsetup -setremotelogin on`.

This will enable remote login on macOS.

Note: This command will prompt you to enter your password.

## Verify Remote Login

1. Run the command `systemsetup -getremotelogin`.
2. If remote login is enabled, you will see "Remote Login: On".

## Related documentation

- [Documentation map](../../../docs/README.md)
