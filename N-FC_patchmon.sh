#!/bin/bash
#Usage: N-FC_patchmon.sh
### Nebulous: Fleet Command Automatic System Reboot Utility | Patch Monitor
# Written By: Andrew W-M
# Licensed under the Apache License 2.0

#Get Script Directory
cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"

#Import Configuration
source $SCRIPT_DIR/config.txt

######### FUNCTIONS
function PullPatchData
{

    while [ -z "$buildid" ]; do
        echo "DEBUG: Pulling Patch Data from Steam"
        bash $SteamcmdDirectory/steamcmd.sh +login anonymous +app_info_print 2353090 +quit > $SCRIPT_DIR/temp/steamoutput.txt
    
        echo "DEBUG: Extracting Build ID"
        buildid=$(grep -A 3 $MonitorBranch $SCRIPT_DIR/temp/steamoutput.txt | grep '"buildid"' | awk '{print $2}' | tr -d '"')
    done

    echo "DEBUG: $MonitorBranch Build ID is currently: $buildid"
}

####### Main Execution
#Create temp dir if doesn't exist
if [ ! -d "$SCRIPT_DIR/temp" ]; then
    mkdir -p "$SCRIPT_DIR/temp"
    echo "DEBUG: Directory '$SCRIPT_DIR/temp' created."
else
    echo "DEBUG: Directory '$SCRIPT_DIR/temp' already exists."
fi

#Make Sure MonitorBranch is set to a valid option
if [ "$MonitorBranch" = 'public' ]; then
    echo "DEBUG: Monitoring Public Branch"
elif [ "$MonitorBranch" = 'testing' ]; then
    echo "DEBUG: Monitoring Test Branch"
else
    echo "DEBUG: Branch Monitor configuration variable incorrect, only the following branches are currently supported: public | testing"
    exit 1
fi

#Check if this is the first-run
if [ ! -f "$SCRIPT_DIR/temp/current_build_id.txt" ]; then 
    echo "DEBUG: Script has not executed previously. Initializing with initial build_id seeding"
    PullPatchData
    echo "current_build_id=$buildid" > $SCRIPT_DIR/temp/current_build_id.txt
    exit 0
else
    echo "DEBUG: Script has been executed previously. Continuing."
fi

#Main Check
PullPatchData
source $SCRIPT_DIR/temp/current_build_id.txt
if [ "$buildid" -le $current_build_id ]; then
    echo "Build IDs match, no changes to upstream. Exiting Script."
    exit 0
else
    echo "Build ID's DO NOT match, calling ASRU Patch Script to update server baseline"
    bash $SCRIPT_DIR/N-FC_ASRU.sh restart patching
    echo "current_build_id=$buildid" > $SCRIPT_DIR/temp/current_build_id.txt
    exit 0
fi
