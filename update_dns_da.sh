#!/bin/ash

# Functions

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

function querypanel4host(){
    local result=""
    result=`curl -s --user ${USERNAME}:${PASSWORD} ${PANELURL}/CMD_API_DNS_CONTROL?domain=${DOMAIN} | sed 's/\t/;/g' | grep "^${HOST2UPDATE};" `
    echo ${result}
}

function updatepanel4host(){                                                                                                                     
    local query=$*                                                                                                                              
    local result=""                                                                                                                             
    result=`curl -s --user ${USERNAME}:${PASSWORD} ${PANELURL}/CMD_API_DNS_CONTROL?domain=${DOMAIN}${query}`
    echo ${result}                                                                                                                              
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
    # Report what we are going to do
    echo "Checking record :  ${HOST2UPDATE}"
    echo "For Domain      :  ${DOMAIN}"

    # Fetch record of hostname from DNS
    DNSQUERY=$(querypanel4host) 

    # Check if output contains the host thus if it's valid
    if [ $(echo ${DNSQUERY} | grep -c ${HOST2UPDATE}) -eq 0 ];
    then
        echo "Host not found, output not as expected."
        echo "${DNSQUERY}"
        echo "Skip further processing for this host."
        continue
    fi

    # Get my external IP address
    MYIP=`curl -s ${MYIPURL}`

    # Get info from query 
    NAME=$(echo ${DNSQUERY} | cut -d ';' -f 1)
    RECORD=$(echo ${DNSQUERY} | cut -d ';' -f 5)

    # Verify outcome of IP addresses
    # DNS record valid
    if ! $(checkip ${RECORD});
    then
        echo "Invalid DNSIP: ${RECORD}"
        echo "Skip further processing for this host."
        continue
    fi

    # My IP valid
    if ! $(checkip ${MYIP});                                                       
    then                                                                                     
        echo "Invalid MyIP: ${MYIP}"
        echo "Skip further processing for this host."
        continue
    fi        

    # Show result
    echo "Retreived DNS record:"          
    echo "DNS record   : ${DNSQUERY}"
    echo "Discovered IP: ${MYIP}" 

    # Check if change is needed
    if [ "${MYIP}" = "${RECORD}" ];
    then
         echo "Records equal, no change needed."
    else
         echo "Records not equal, updating DNS"
         QUERY=$(updatepanel4host "&action=edit&type=A&arecs0=name%3D${NAME}%26value%3D${RECORD}&name=${NAME}&value=${MYIP}")
         # Check if output contains a new serialnumber thus if DNS is updated
         if [ $(echo ${QUERY} | grep -c "error=0") -eq 0 ];                                                                
         then 
             echo "Host not found, output not as expected." 
             echo "${QUERY}"
         else
             echo "Update DNS record succeded."
         fi            
    fi
done
