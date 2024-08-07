#!/bin/bash
#Usage: N-FC_ASRU.sh {Script Operation}
### Nebulous: Fleet Command Automatic System Reboot Utility
# Written By: Andrew W-M
# Licensed under the Apache License 2.0

#VARIABLES
#Get Script Directory
cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"

#Import Configuration
source $SCRIPT_DIR/config.txt

Script_Execution=0
Server_Command=0

ServerIP=$(curl ipv4.icanhazip.com)

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

function SendNFCServerCommand {
  #If Server Command has not yet been printed out, generate file.
  #Dedicated Server will only execute this once, so no point running it on a loop.
  if [ $Server_Command -lt 1 ]
  then
    #Stage Ingame Message based on Script Input
    if [ "$2" = "scheduled" ]
    then
      echo "DEBUG: Scheduled Reboot Message Queued"
      $ServerMessage=$RebootReason_Scheduled
    elif [ "$2" = "patch" ]
    then
      echo "DEBUG: Patching Reboot Message Queued"
      $ServerMessage=$RebootReason_Patching
    elif [ "$2" = "admin" ]
    then
      echo "DEBUG: Admin Reboot Message Queued"
      $ServerMessage=$RebootReason_Admin
    elif [ "$1" = "stop" ]
    then
      echo "DEBUG: Admin Reboot Message Queued"
      $ServerMessage=$ShutdownReason
    else
      echo "DEBUG: Unsupported Reboot Message Listed, defaulting to Patching Message."
      $ServerMessage=$RebootReason_Patching
    fi

    echo "DEBUG: Sending N:FC ServerCommand"
    cat << EOF > $SCRIPT_DIR/ServerCommand.xml
<ServerCommandFile>
    <Command>ScheduleRestart</Command>
    <Message>$ServerMessage</Message>
</ServerCommandFile>
EOF
    mv $SCRIPT_DIR/ServerCommand.xml $NebulousConfigLocation/ServerCommand.xml
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
#Valid options are: stop, restart, forcepatch
if [ "$1" = "stop" ]
then
    echo "DEBUG: Stop Service confirmed"
elif [ "$1" = "restart" ]
then
    echo "DEBUG: Restart Service confirmed"
elif [ "$1" = "forcepatch" ]
then
    echo "DEBUG: Forcing Patch Nebulous confirmed"
elif [ "$1" = "help" ]
then
    echo "DEBUG: Print Help Information"
else
    echo "DEBUG: Incorrect Option Selected, only the following options are supported: stop | restart | forcepatch | help"
    exit 1
fi

#If the script is called with "patch" specified, it immediately stops the Neb Server and begins patching. 
if [ "$1" = "forcepatch" ]; then
  echo "DEBUG: Shutting Down Services for Immediate Patching"
  StopNFCServer
  PatchNebulousServer
  StartNFCServer
  echo "DEBUG: Patching complete, exiting script."
  exit 0
fi

#If the script is called with "help" specified, script exits and prints help information.
if [ "$1" = "help" ]; then
  echo "Nebulous: Fleet Command Automatic System Reboot Utility"
  echo "The purpose of this script is to support the running of a Nebulous Fleet Command Dedicated Server"
  echo "Supported Arguements are listed below:"
  echo "stop       | Stops Nebulous Fleet Command service at the end of the current game if running."
  echo "restart    | Restarts Nebulous Fleet Command service at the end of the current game, and patches binaries if needed."
  echo "forcepatch | Forces a restart without regard for game status."
  echo "help       | Displays this help text."
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
