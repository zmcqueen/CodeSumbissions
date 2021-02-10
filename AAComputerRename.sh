#!/bin/bash
# By Zack McQueen
# Written 2021/02/08
# For use at App Annie only

# Set variables here:
maxStringLength=63
apiURL="https://jss.appannie.org:10023/JSSResource/computers/macaddress/" # could be replaced with $6 in Jamf if we want to keep our URL private also
apiUser=$4 
apiPass=$5
MacAdd=$( /usr/sbin/networksetup -getmacaddress en0 | /usr/bin/awk '{ print $3 }' | /usr/bin/sed 's/:/./g' )

setNames() {
    # Set the ComputerName, hostName and LocalhostName
    scutil --set ComputerName "$hostName"
    scutil --set HostName "$hostName"
    scutil --set LocalHostName "$hostName"
}

reportNamesToJamf() {
    /usr/local/bin/jamf setComputerName -name "$hostName"
    /usr/local/bin/jamf recon -endUsername "$user"
}

trimUsername() {
    local userStringLength
    trimLength=$(( ${#hostName} - maxStringLength ))
    userStringLength=$(( ${#hostName} - trimLength))
    # Gets the length of name allowed with given model info
    hostName=$(echo "$hostName" | cut -c -$userStringLength)
    # echo $currentUser
}

processComputerName() {
local preProcessedComputerName

# add first and last together
preProcessedComputerName=$("AA" + "$siteAbbreviation" + "$firstInitial" + "$lastName")
echo "computer name: " + "$preProcessedComputerName"

# clean illegal characters
preProcessedComputerName=$(echo "$preProcessedComputerName" | tr -cd "[:alnum:]")

# clean up preProcessedComputerName to have all upper case
hostName=$(echo "$preProcessedComputerName" | awk '{print toupper($0)}')

}

# ~~~~~~~~~~~~~

# Fetch site name from Jamf API
siteName=$( /usr/bin/curl -sku $apiUser:$apiPass $apiURL$MacAdd/subset/general  -X GET -H "Accept: application/xml"  | /usr/bin/xpath /computer/general/site/name |/usr/bin/sed 's/<name>//;s/<\/name>//' )
if [[ "$siteName" != "" ]]; then
    echo "$siteName"
else
        echo "Not Available"
fi

# Get shortened site name
case $siteName in
"Beijing")
    siteAbbreviation="BJ"
    ;;
"Berlin")
    siteAbbreviation="BE"
    ;;
"Brazil")
    siteAbbreviation="BR"
    ;;
"Japan")
    siteAbbreviation="JP"
    ;;
"London")
    siteAbbreviation="LO"
    ;;
"New York")
    siteAbbreviation="NY"
    ;;
"Other")
    siteAbbreviation="OT"
    ;;
"Paris")
    siteAbbreviation="PA"
    ;;
"Russia")
    siteAbbreviation="RU"
    ;;
"San Francisco")
    siteAbbreviation="SF"
    ;;
"Shanghai")
    siteAbbreviation="SH"
    ;;
"Singapore")
    siteAbbreviation="SG"
    ;;
"South Korea")
    siteAbbreviation="SK"
    ;;
"Utrecht")
    siteAbbreviation="UT"
    ;;
"Vancouver")
    siteAbbreviation="VA"
    ;;
*)
    echo "Site name doesn't exist in script - update script with new sitename: $siteName"
    exit 1
esac

echo "Shortened to: $siteAbbreviation"

# figure out the local user
user=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
echo "User: " + "$user"

#figure out the user's full name
name=$(finger "$user" | awk -F: '{ print $3 }' | head -n1 | sed 's/^ //' )
echo "Name: " + "$name"

# get first initial
firstInitial="$(echo "$name" | head -c 1)"
echo "$firstInitial"

# get last name
lastName="$(echo "$name" | cut -d \  -f 2)"
echo "Last: " + "$lastName"

# DEBUG BLOCK to check text trimming and character cleaning
lastName="user's big long name with all kinds of garbage in here234523452345! It %@(*@%) apparently needs to be even longer??????"

# add first initial and last name together
preProcessedComputerName=$(echo "AA$siteAbbreviation$firstInitial$lastName")
echo "computer name: " + "$preProcessedComputerName"

# clean illegal characters
preProcessedComputerName=$(echo "$preProcessedComputerName" | tr -cd "[:alnum:]")

# clean up preProcessedComputerName to have all upper case
hostName=$(echo "$preProcessedComputerName" | awk '{print toupper($0)}')

# Check the length of the name after cleaning and trim if necessary
hostNameLength=${#hostName}
echo "$hostNameLength"
if [ "$hostNameLength" -gt 62 ]
then
    echo "$hostNameLength is too long, max 63 char"
    trimUsername
    echo "Reduced to ${#hostName} characters"
fi
echo "$hostName"

setNames
reportNamesToJamf
exit 0