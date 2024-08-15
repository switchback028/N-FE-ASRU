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
    echo "DEBUG: Pulling Patch Data from Steam"
    bash $SteamcmdDirectory/steamcmd.sh +login anonymous +app_info_print 2353090 +quit > $SCRIPT_DIR/temp/steamoutput.txt
}

function ExtractBuildID_public
{
    echo "DEBUG: Extracting Public Build ID"
    buildid_public=$(grep -A 3 '"public"' $SCRIPT_DIR/temp/steamoutput.txt | grep '"buildid"' | awk '{print $2}' | tr -d '"')
    echo "DEBUG: Public Build ID is currently: $buildid_public"
}

function ExtractBuildID_testing
{
    echo "DEBUG: Extracting Testing Build ID"
    buildid_testing=$(grep -A 3 '"testing"' $SCRIPT_DIR/temp/steamoutput.txt | grep '"buildid"' | awk '{print $2}' | tr -d '"')
    echo "DEBUG: Testing Build ID is currently: $buildid_testing"
}

####### Main Execution
#Create temp dir if doesn't exist
if [ ! -d "$SCRIPT_DIR/temp" ]; then
    mkdir -p "$SCRIPT_DIR/temp"
    echo "DEBUG: Directory '$SCRIPT_DIR/temp' created."
else
    echo "DEBUG: Directory '$SCRIPT_DIR/temp' already exists."
fi

#Check if this is the first-run
if [ ! -f "$SCRIPT_DIR/temp/current_build_id.txt" ]; then
    echo "DEBUG: Script has not executed previously. Initializing with initial build_id seeding"
    PullPatchData
    if [ "$MonitorBranch" = 'public' ]
    then
        ExtractBuildID_public
        echo $buildid_public > $SCRIPT_DIR/temp/current_build_id.txt
        exit 0
    elif [ "$MonitorBranch" = 'testing' ]
    then
        ExtractBuildID_testing
        echo $buildid_testing > $SCRIPT_DIR/temp/current_build_id.txt
        exit 0
    else
        echo "DEBUG: Branch Monitor configuration variable incorrect, only the following branches are currently supported: public | testing"
        exit 1
    fi
else
    echo "DEBUG: Script has been executed previously. Continuing."
fi

#Pull Current Patch Data
PullPatchData

#Main Check
if [ "$MonitorBranch" = "public" ]
then
    echo "DEBUG: Monitoring Public Branch"
    ExtractBuildID_public
    if [ "$buildid_public" -le $(cat $SCRIPT_DIR/temp/current_build_id.txt) ]
    then
        echo "Build IDs match, no changes to upstream. Exiting Script."
        exit 0
    else
        echo "Build ID's DO NOT match, calling ASRU Patch Script to update server baseline"
        bash $SCRIPT_DIR/N-FC_ASRU.sh restart patching
        echo $buildid_public > $SCRIPT_DIR/temp/current_build_id.txt
        exit 0
    fi
elif [ "$MonitorBranch" = "testing" ]
then
    echo "DEBUG: Monitoring Testing Branch"
    ExtractBuildID_testing
    if [ "$buildid_testing" -le $(cat $SCRIPT_DIR/temp/current_build_id.txt) ]
    then
        echo "Build IDs match, no changes to upstream. Exiting Script."
        exit 0
    else
        echo "Build ID's DO NOT match, calling ASRU Patch Script to update server baseline"
        bash $SCRIPT_DIR/N-FC_ASRU.sh restart patching
        echo $buildid_testing > $SCRIPT_DIR/temp/current_build_id.txt
        exit 0
    fi
else
    echo "DEBUG: Branch Monitor configuration variable incorrect, only the following branches are currently supported: public | testing"
    exit 1
fi