#!/bin/bash
# N-FC_ASRU.sh
### Nebulous: Fleet Command Automatic System Reboot Utility
# Written By: Andrew W-M (Switchback#6290)
# Licensed under the Apache License 2.0

#VARIABLES
source config.txt

Script_Execution=0
Server_Command=0

#Functions
function QuerySteamAPI {
  apiurl="https://api.steampowered.com/IGameServersService/GetServerList/v1/?key=$APIKey&filter=addr\\${ServerIP}:$SteamPort"
  apiresult=$(curl -X GET --header "Accept: */*" "$apiurl")
  neb_players=$(echo $apiresult | jq -r '.response.servers[0].players')
  echo "DEBUG: There are currently " $neb_players "players on the server"
}

function StartNFCServer {
  echo "DEBUG: Starting Nebulous Fleet Command Dedicated Server"
  systemctl start $NebServiceName.service
}

function RestartNFCServer {
  echo "DEBUG: Restarting Nebulous Fleet Command Dedicated Server"
  systemctl restart $NebServiceName.service
}

function RestartSystem {
  echo "DEBUG: Restarting System"
  init 6
}

function SendNFCServerCommand {
  if [ $Server_Command -lt 1 ]
  then
    echo "DEBUG: Sending N:FC ServerCommand"
    cat << EOF > ServerCommand.xml
<ServerCommandFile>
    <Command>ScheduleRestart</Command>
    <Message>$RebootReason</Message>
</ServerCommandFile>
EOF
    mv ServerCommand.xml $NebulousConfigLocation/ServerCommand.xml
fi
}

function DeleteNFCServerCommand {
  if [ $Server_Command -lt 1 ]
  then
    rm -f $NebulousConfigLocation/ServerCommand.xml
fi
}

#Main Execution, now with LOOPS!
while [ $Script_Execution -lt 1 ]
do
  #Check if Server is Running
  if systemctl is-active --quiet "$NebServiceName.service" ; then
    echo "DEBUG: Nebulous Fleet Command Dedicated Server is Running, Continuing."
    QuerySteamAPI
  else
    echo "DEBUG: Nebulous Fleet Command Dedicated Server is NOT running, starting Service."
    StartNFCServer
    DeleteNFCServerCommand
    exit
  fi

  #Check Player Count
  if [ $neb_players -gt 0 ]
  then
    echo "DEBUG: There are currently " $neb_players "online!"
    SendNFCServerCommand
    Server_Command=1
    sleep $APIQueryTime
  else
    echo "DEBUG: Restarting Nebulous Fleet Command Dedicated Server."
    RestartNFCServer
    DeleteNFCServerCommand
    exit
  fi
done