#!/bin/bash
#Usage: N-FC_ASRU.sh {Script Operation}
### Nebulous: Fleet Command Automatic System Reboot Utility
# Written By: Andrew W-M
# Licensed under the Apache License 2.0

#VARIABLES
source config.txt

Script_Execution=0
Server_Command=0

#Functions
function QuerySteamAPI {
  apiurl="https://api.steampowered.com/IGameServersService/GetServerList/v1/?key=$APIKey&filter=addr\\${ServerIP}:$SteamPort"
  apiresult=$(curl -X GET --header "Accept: */*" "$apiurl")
  if [[ "$apiresult" == *"Access is denied"* ]]; then
    echo "DEBUG: API Key Invalid, Exiting Script."
    echo "ERROR: API Key is Incorrect, Please Update API Key in config.txt" >> error.txt
    exit 1
  fi
  neb_players=$(echo $apiresult | jq -r '.response.servers[0].players')
  echo "DEBUG: There are currently " $neb_players "players on the server"
}

function StartNFCServer {
  echo "DEBUG: Starting Nebulous Fleet Command Dedicated Server"
  systemctl start $NebServiceName.service
}

function StopNFCServer {
  echo "DEBUG: Stopping Nebulous Fleet Command Dedicated Server"
  systemctl stop $NebServiceName.service
}

function RestartNFCServer {
  echo "DEBUG: Restarting Nebulous Fleet Command Dedicated Server"
  systemctl restart $NebServiceName.service
}

#function RestartSystem {
#  echo "DEBUG: Restarting System"
#  init 6
#}

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

function PatchNebulousServer {
  echo "DEBUG: Patching Nebulous Server Files"
  bash $SteamcmdDirectory/steamcmd.sh +runscript $NebServerPatchScript
}

#Main Execution

#First validate that Script Modifier is valid option. If valid option is displayed, reboot. 
#Valid options are: stop, restart, patch
if [ "$1" = "stop" ]
then
    echo "DEBUG: Stop Service confirmed"
elif [ "$1" = "restart" ]
then
    echo "DEBUG: Restart Service confirmed"
elif [ "$1" = "patch" ]
then
    echo "DEBUG: Patch Nebulous confirmed"
else
    echo "DEBUG: INCORRECT OPTION CALLED, EXITING."
    exit 1
fi

#If the script is called with "patch" specified, it immediately stops the Neb Server and begins patching. 
if [ "$1" = "patch" ]; then
  echo "DEBUG: Shutting Down Services for Immediate Patching"
  StopNFCServer
  PatchNebulousServer
  StartNFCServer
  echo "DEBUG: Patching complete, exiting script."
  exit 0
fi

while [ $Script_Execution -lt 1 ]
do
  #Check if Server is Running
  if systemctl is-active --quiet "$NebServiceName.service" ; then
    echo "DEBUG: Nebulous Fleet Command Dedicated Server is Running, Continuing."
    QuerySteamAPI
  else
    echo "DEBUG: Nebulous Fleet Command Dedicated Server is NOT running."
    DeleteNFCServerCommand
    #Below Loop runs if the service stops unexpectedly, but the script is scheduled for restart operation.
    if [ "$1" = "stop" ]
    then
      if [ "$PatchOnBoot" = "1" ]; then
        PatchNebulousServer
      fi
      echo "DEBUG: Stop Issued, Exiting Script."
      exit 0
    elif [ "$1" = "restart" ]
    then
      if [ "$PatchOnBoot" = "1" ]; then
        PatchNebulousServer
      fi
      echo "DEBUG: Starting Nebulous Fleet Command Service."
      StartNFCServer
      exit 0
    fi
  fi

  #Check Player Count
  if [ $neb_players -gt 0 ]
  then
    echo "DEBUG: There are currently " $neb_players "online!"
    SendNFCServerCommand
    Server_Command=1
    sleep $APIQueryTime
  else
    echo "DEBUG: All players have left the server."
    if [ "$1" = "stop" ]
    then
      echo "DEBUG: Stop Issued, Stopping Server. Exiting Script."
      StopNFCServer
      exit 0
    elif [ "$1" = "restart" ]
    then
      echo "DEBUG: Restarting Nebulous Fleet Command Service."
      StopNFCServer
      if [ "$PatchOnBoot" = "1" ]; then
        PatchNebulousServer
      fi
      StartNFCServer
      exit 0
    fi
    DeleteNFCServerCommand
    exit 0
  fi
done
