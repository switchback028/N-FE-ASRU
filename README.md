# N-FE-ASRU
Nebulous: Fleet Command Automatic Server Reboot Utility

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
