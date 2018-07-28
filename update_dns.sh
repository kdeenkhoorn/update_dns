#!/bin/ash

# Functions
# https://gist.github.com/cjus/1047794
function jsonval(){

    local jstring=$2
    local result=""

    result=`echo "${jstring}" | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | sed 's/\[/,/g' | sed 's/\]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"//g' | grep -w $1`
    echo ${result}
}

# Return value from parameter:value pair
function getval(){

    local valuepair=$*
    local result=""

    result=`echo "${valuepair}" | cut -d ':' -f 2`
    echo ${result}
}
function querycpanel(){

    local query=$*
    local result=""

    result=`curl -s --user ${USERNAME}:${PASSWORD} ${CPANELURL}'json-api/cpanel?cpanel_jsonapi_user=user&cpanel_jsonapi_apiversion=2&cpanel_jsonapi_module=ZoneEdit&'${query}` 
    echo ${result}
}

# Check if valid IP address
function checkip() {

    local ip=$1

    if expr "${ip}" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/nul;
    then 
        return 0                                                                                                      
    else 
        return 1                                                                                                         
    fi    
}

##############
# Main program
##############

# Read settingsfile with instructions what to do                                                                      
DIR=$(dirname "$0")                                                                                                   
if ! test -f ${DIR}/settings.ini ;                                                                                    
then                                                                                                                  
    echo "${DIR}/settings.ini not found."                                                                             
    exit 1                                                                                                            
else                                                                                                                  
    source ${DIR}/settings.ini                                                                                        
fi   

# Start to loop though all hosts we should update
# Replace all , for spaces in the list of hosts to update
for HOST2UPDATE in ${HOSTS//,/ }
do
    # Check if HOST2UPDATE ends FQDN, ends with a dot
    if [ ! "${HOST2UPDATE:$((${#HOST2UPDATE}-1)):1}" = "." ];
    then
         HOST2UPDATE="${HOST2UPDATE}."
    fi

    # Report what we are going to do
    echo "Checking record :  ${HOST2UPDATE}"
    echo "For Domain      :  ${DOMAIN}"

    # Fetch record of hostname from DNS
    JSON=$(querycpanel "cpanel_jsonapi_func=fetchzone_records&domain=${DOMAIN}&name=${HOST2UPDATE}")

    # Check if output contains the host thus if it's valid
    if [ $(echo ${JSON} | grep -c ${HOST2UPDATE}) -eq 0 ];
    then
        echo "Host not found, output not as expected."
        echo "${JSON}"
        echo "Skip further processing for this host."
        continue
    fi

    # Get my external IP address
    MYIP=`curl -s ${MYIPURL}`

    # Get info from query 
    LINE=$(getval $(jsonval "line" ${JSON}))
    NAME=$(getval $(jsonval "name" ${JSON}))
    TTL=$(getval $(jsonval "ttl" ${JSON}))
    CLASS=$(getval $(jsonval "class" ${JSON}))
    TYPE=$(getval $(jsonval "type" ${JSON}))
    RECORD=$(getval $(jsonval "record" ${JSON}))

    # Verify outcome of IP addresses
    # DNS record valid
    if ! $(checkip ${RECORD});
    then
        echo "Invalid IP: ${RECORD}"
        echo "Skip further processing for this host."
        continue
    fi

    # My IP valid
    if ! $(checkip ${MYIP});                                                       
    then                                                                                     
        echo "Invalid IP: ${MYIP}"
        echo "Skip further processing for this host."
        continue
    fi        

    # Show result
    echo "Retreived DNS record:"          
    echo "Line:"${LINE} ${NAME} ${TTL} ${CLASS} ${TYPE} ${RECORD}

    # Check if change is needed
    if [ "${MYIP}" = "${RECORD}" ];
    then
         echo "Records equal, no change needed."
    else
         echo "Records not equal, updating DNS"
         JSON=$(querycpanel "cpanel_jsonapi_func=edit_zone_record&line=${LINE}&domain=${DOMAIN}&name=${HOST2UPDATE}&type=${TYPE}&address=${MYIP}&ttl=${TTL}&class=${CLASS}")
         # Check if output contains a new serialnumber thus if DNS is updated
         if [ $(echo ${JSON} | grep -c "newserial") -eq 0 ];                                                                
         then 
             echo "Host not found, output not as expected." 
             echo "${JSON}"
         else
             echo "Update DNS record succeded."
         fi            
    fi
done
