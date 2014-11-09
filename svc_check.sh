#!/bin/bash
# (re)Start a service on a remote machine if it doesn't respond on a given list of ports
# Author: Jacek Lakomiec
# Date: 09 Nov 2014
# Version: 0.1

# Define basic variables. Make sure you replace SSH_USER and SSH_KEY values
IP="$1"
PORTS=$( echo $2 | sed -e "s#,# #g")
LOGFILE="log_svc_check-`date +%Y%m%d`.log"
SSH_USER=vagrant
SSH_KEY=vagrant-debian64

# Make sure the script has enough parameters and if not, present expected usage
if [ $# -lt 2 ]; then
    echo "Usage: $0 <IP> <port1,port2,portN>"
    exit 1
fi

# Check if nc binary is present on the system
if [ ! -x /bin/nc ]; then
    echo "This script requires netcat (nc) binary installed on this system"
    exit 1
fi

# Iterate through the list of ports, check if there is any response from remote host on that port and if not,
# login via ssh and restart a service name expected to be running on that port.  
for port in $PORTS; do
    nc -z $IP $port
    RES=$(echo $?)
    if [ $RES -eq 0 ]; then
        echo "Port: $port on IP $IP is open for connections" 2>&1 >> $LOGFILE
    else
        echo "The port $port on IP $IP seems down. I will login to $IP and restart the service running on port ${port}." 2>&1 >> $LOGFILE

        # port number <> service name mapping is required in order to restart appropriate services on the remote machine
        case $port in
            21)
                service_name="pure-ftpd"
                ;;
            25)
                service_name="exim4"
                ;;
            80|443)
                service_name="apache2"
                ;;
            3306)
                service_name="mysql"
                ;;
        esac

        ssh -i $SSH_KEY -l $SSH_USER $IP "sudo /etc/init.d/${service_name} restart" 2>&1 >> $LOGFILE
    fi
done

exit 0

