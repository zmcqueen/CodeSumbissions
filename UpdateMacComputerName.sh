#!/bin/bash
# macOS Computer Renaming Script
# By Zack McQueen
# Created 2020/10/20

getCurrentUser() {
currentUser=$(id -P $(stat -f%Su /dev/console) | awk -F '[:]' '{print $8}')
# -F hasn't been tested on Sierra and older
echo "Logged in user is: $currentUser"
if [[ -z $currentUser ]]; then
  echo "Logged in user not available - exiting"
  exit 1
fi
}

setModelInfo() {
  # Cuts the computer type out and cleans up whitespace
  # sed removes everything after the second comma to remove "Four Thunderbolt 3 Ports"
  modelInfo=$(echo $computerModel \
    | awk '{split($0, a, "("); print a[2]}')
  modelInfo=$( echo "${modelInfo:0:${#modelInfo}-1}" \
    | cut -f1,2 -d',' )
  # echo "MODEL INFO PASSED: $modelInfo"
}

getComputerType() {
  # Gets the nice, clean string from SystemProfiler
  computerModel=$(defaults read \
    ~/Library/Preferences/com.apple.SystemProfiler.plist 'CPU Names' \
    | cut -sd '"' -f 4 \
    | uniq)
  # Debug:
  # computerModel="MacBook Pro (16-inch, 2019, Four Thunderbolt 3 Ports)"
  # echo "Model String: $computerModel"
  # Check for the model, exit if model fetch failed
  if [[ ! -z $computerModel ]]; then
    computerType=$(echo $computerModel \
      | awk '{split($0, a, "("); print a[1]}' \
      | xargs)
    setModelInfo
  else
    echo "Computer Model not available - exiting"
    exit 1
  fi

}

trimUsername() {
  trimLength=$(( ${#computerName} - 63 ))
  if [[ $trimLength -gt 0 ]]; then
    userStringLength=$(( ${#currentUser} - $trimLength))
    # Gets the length of name allowed with given model info
    currentUser=$(echo $currentUser \
      | cut -c -$userStringLength)
    # echo $currentUser
    createComputerName
  fi
}

createComputerName()
  # Combine into the user-readable string
  computerName="$currentUser's $computerType ($modelInfo)"
  local alphanumModelInfo=$(echo ${modelInfo//,/})
  # Debug
  # echo "${#computerName} characters - $computerName"
  # Combine into the network-readable string
  spacelessName="${currentUser// /-}s-${computerType// /-}-${alphanumModelInfo// /-}"
  echo $spacelessName
}

setComputerName() {
  scutil --set HostName "$spacelessName"
  scutil --set LocalHostName "$spacelessName"
  scutil --set ComputerName "$computerName"
  dscacheutil -flushcache
}

getCurrentUser
getComputerType
createComputerName
# Checks computer name length for Office and bonjour compatibility
if [[ ${#computerName} -gt 63 ]]; then
  trimUsername
fi

setComputerName
/usr/local/bin/jamf recon
