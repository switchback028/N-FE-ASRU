## Nebulous: Fleet Command Automatic Server Reboot Utility

## Description
The purpose of this script is to give Nebulous: Fleet Command dedicated server owners the ability to automatically restart, patch and stop the Server in such a way that allows an in-progress game to end without impacting the users on the server. As of now the features include:
- Stateful restart/stop/start of the game service to allow an in-progress game to be completed prior to reboot.
- Automatic patching of the Nebulous Server Binaries by using steamcmd (Installed Separately by the User)

## Installation
Prerequisites:
1. The following Linux packages are required, please install these for the script to work. The following example is for Debian 11 and may change based on your Operating System:
apt-get -y install jq curl
2. Nebulous: Fleet Command is running as a service. 
3. Your server runs systemd. (Service commands start with systemctl)
4. You have a basic understanding of how to run cronjobs. 


Installation Steps:
1. Clone Repository to location of your choice. 
2. Edit the config.txt file and input all variables. 
3. Run the script manually or have it execute automatically as a cronjob.

## Usage
Update the config.txt file with the all variables and paths as needed. 

bash N-FC_ASRU.sh [ stop / restart / patch ]
- "stop" flag will gracefully stop the Nebulous Server at the end of a game, if onei s in progress.
- "restart" flag will gracefully restart the Nebulous Server at the end of a game, if one is in progress.
- "patch" flag will shutdown and patch nebulous. NOTE: This is not a graceful shutdown. Only intended to use the patch flag for new server version patching.

## Support
If you need help with this script, please contact Switchback77 on Discord. 
If you encounter a script issue please open a PR. 

## Roadmap
No Current Additions are planned at this time. 

## License
This Software is licensed under the Apache License 2.0