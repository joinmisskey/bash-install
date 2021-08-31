# Misskey install shell script v1.0.0
Install Misskey with one shell script!  

You can install misskey on an Ubuntu server just by answering some questions.  

There is also an update script.

[**日本語版はこちら**](./README.md)

## Ingredients
1. A Domain
2. An Ubuntu Server
3. A Cloudflare Account (recommended)

## Procedures
### 1. SSH
Connect to the server via SSH.  
(If you have the desktop open, open the shell.)

### 2. Clean up
Make sure all packages are up to date and reboot.

```
sudo apt update; sudo apt full-upgrade -y; sudo reboot
```

### 3. Start the installation
Reconnect SSH and let's start installing Misskey. 

```
wget https://raw.githubusercontent.com/joinmisskey/bash-install/main/ubuntu.sh -O ubuntu.sh; sudo bash ubuntu.sh
```

### 4. To update
There is also an update script.

First, download the script.

```
wget https://raw.githubusercontent.com/joinmisskey/bash-install/main/update.ubuntu.sh -O update.sh;
```

Run it when you want to update Misskey.

```
sudo bash update.sh
```

- In the systemd environment, the `-r` option can be used to update and reboot the system.
- In the docker environment, you can specify repository:tag as an argument.

## Environments in which the operation was tested

### Oracle Cloud Infrastructure

This script runs well on following compute shapes complemented by Oracle Cloud Infrastructure Always Free services.

- VM.Standard.E2.1.Micro (AMD)
- VM.Standard.A1.Flex (ARM) [1OCPU RAM6GB or greater]

## Issues & PRs Welcome
If it does not work in the above environment, it may be a bug. We would appreciate it if you could report it as an issue, with the specified requirements you entered to the script.

It is difficult to provide assistance for environments other than the above, but we may be able to solve your problem if you provide us with details of your environment.

Suggestions for features are also welcome.
