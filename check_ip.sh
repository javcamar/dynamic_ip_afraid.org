#!/bin/bash

# Procedure updated May 2025

#----------------       PROGRAM PARAMETERS      --------------------------------------
# Please customize with your own parameters:

  # Specify the domain that should point to your external IP (must be registered at afraid.org)
DOM_CHEQUEO=exampledomain.mooo.com
declare -A TOKENS #Declare associative array for Tokens

  # here you must specify the Tokens provided by afraid.org for every domain that you want to register with your public ip.
TOKENS["exampledomain.com"]="myafraid.orgtokenmyafraid.orgtokenmyafraid.orgtoken" #Update token for exampledomain.com (afraid.org)
TOKENS["exampledomain2.com"]="myafraid.orgtokenmyafraid.orgtokenmyafraid.orgtoken" #Update token for exampledomain2.com (afraid.org)
TOKENS["exampledomain3.com"]="myafraid.orgtokenmyafraid.orgtokenmyafraid.orgtoken" #Update token for exampledomain3.com (afraid.org)
  

# name here your log file for debugging (without .log extension, it adds automatically).
LOG=/var/log/check_ip

# These parameters do not require customization.
CHIP=("ipinfo.io/ip" "icanhazip.com" "ident.me" "api.ipify.org" "checkip.amazonaws.com" "ifconfig.co") # External sources to detect external IP.
STATUS=0 #Status if there are no errors.
NS=("8.8.4.4" "8.8.8.8" "70.39.97.253" "67.220.81.190" "69.65.50.223" "69.65.50.194") #DNS servers to use in sequence if errors occur
#------------------------------------------------------------------------------------------

# ------------------ FUNCTIONS ------------------

#Load logging tools
. /usr/local/bin/logsutils.lib #this file provides separately, is only for logging purposes

# Function to check if a string is a valid IP
function es_ip_valida () {
  # Check for IP format (number.number.number.number)
  if [[ ! "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    return 1
  fi

  # Split the four octets using the dot as separator
  IFS='.' read -r o1 o2 o3 o4 <<< "$1"

  # Check that each octet is in the 0–255 range
  for octeto in $o1 $o2 $o3 $o4; do
    if (( octeto < 0 || octeto > 255 )); then
      return 1
    fi
  done

  return 0
}

#------------------------------------------------------------------------------------------

# Function to update in afraid.org (must receive the token as parameter1 and domain as parameter2)
function freedns () {
  log "Updating $2 -> " 1
  local hash=$1
  local action="curl -s https://freedns.afraid.org/dynamic/update.php?$hash"
  local res=$($action)
  if [[ $res == *Updated* ]]; then
    log "OK -> Updated" 2
  else
    log "ERROR -> Could not update -> '$res'" 2
  fi
}

# Function to get the current external IP
function get_external_ip () {
  for EXT in "${CHIP[@]}"; do
    log "Checking with curl (current IP) at $EXT -> " 1
    RESPUESTA=$(timeout 10 curl -s --fail -4 "$EXT")
    CURL_STATUS=$?
    # Check for errors and valid IP
    if [ $CURL_STATUS == 0 ] || es_ip_valida "$RESPUESTA"; then
      log "OK -> [$RESPUESTA]" 2
      echo $RESPUESTA
      return 0
      break
    fi
    log "ERROR -> $CURL_STATUS -> [$RESPUESTA]" 2
  done
  return 1
}

# Function that gets the IP registered in DNS servers (previous IP)
function get_old_ip () {
  for DNS in "${NS[@]}"; do
    log "Checking with dig (previous IP) at NS=[$DNS] -> " 1
    RESPUESTA=$(dig @$DNS "$DOM_CHEQUEO" +short -4)
    if es_ip_valida "$RESPUESTA"; then
      log "OK -> [$RESPUESTA]" 2
      echo $RESPUESTA
      return 0
      break
    else
      log "ERROR -> [$RESPUESTA]" 2
    fi
  done
  log "ERROR -> All dig queries failed."
  return 2
}

#                   |~~~~~~~~~~~~~~~~~~~~~~~~~~~|
#                   |     MAIN PROCEDURE        |
#                   |~~~~~~~~~~~~~~~~~~~~~~~~~~~|

# Prepare the log using external library

RES="$( logsize $LOG 1 5 )" # logsize megabytes files (logsize $LOG 1 5) It means that the log file must not exceed 1 MB and that the last 5 files are always kept.
LOG=$LOG.log

log "" 2
log "---------------> [ Starting check and update IP ] <---------------" 
log "$RES"

# Get external IP using curl
IPADDR=$(get_external_ip)
STATUS=$?

# Get public IP registered in DNS using dig
if [ $STATUS == 0 ]; then
  IPOLD=$(get_old_ip)
  STATUS=$?
fi


# Check for errors, otherwise continue
if [ $STATUS -ne 0 ]; then
  log "ERROR: $STATUS - Aborting update"
  exit $STATUS
fi

# If IP exists and is different, update
if [ "$IPADDR" = "$IPOLD" ]; then
  log "No IP change <<<===>>> Previous IP [$IPOLD] <<<===>>> Current IP [$IPADDR]"
else
  log "Change detected: Previous IP [$IPOLD] - Current IP [$IPADDR]"
  for DOM in "${!TOKENS[@]}"; do
    TOKEN="${TOKENS[$DOM]}"
    freedns $TOKEN $DOM
  done
fi
