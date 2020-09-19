#!/bin/bash
#This script get and set basic network information 
if [[ -f variables.sh ]]
then
  source variables.sh
fi

read -rp "IDM Hostname to use: ($IDMHOSTNAME): " choice; [[ -n "${choice}"  ]] &&  export IDMHOSTNAME="$choice"; 
read -rp "IDM IP to use: ($IDMIP): " choice; [[ -n "${choice}"  ]] &&  export IDMIP="$choice"; 
read -rp "IDM Netmask to use (just the number of bits): ($IDMNETMASK): " choice;[[ -n "${choice}"  ]] &&  export IDMNETMASK="$choice"; 
read -rp "IDM GW to use: ($IDMGW): " choice; [[ -n "${choice}"  ]] &&  export IDMGW="$choice";
read -rp "Foreman Hostname to use: ($ForemanHOSTNAME): " choice;[[ -n "${choice}"  ]] &&  export ForemanHOSTNAME="$choice";
read -rp "Foreman IP to use: ($ForemanIP): " choice; [[ -n "${choice}"  ]] &&  export ForemanIP="$choice";
read -rp "Foreman Netmask to use (just the number of bits): ($ForemanNETMASK): " choice;	[[ -n "${choice}"  ]] &&  export ForemanNETMASK="$choice";
read -rp "Foreman GW to use: ($ForemanGW): " choice; [[ -n "${choice}"  ]] &&  export ForemanGW="$choice";
read -rp "Foreman Global DNS to use: ($ForemanDNSSERVER): " choice;	[[ -n "${choice}"  ]] &&  export ForemanDNSSERVER="$choice";

echo "export IDMHOSTNAME=$IDMHOSTNAME" > variables.sh
echo "export IDMIP=$IDMIP" >> variables.sh
echo "export IDMNETMASK=$IDMNETMASK" >> variables.sh
echo "export IDMGW=$IDMGW" >> variables.sh
echo "export ForemanHOSTNAME=$ForemanHOSTNAME" >> variables.sh
echo "export ForemanIP=$ForemanIP" >> variables.sh
echo "export ForemanNETMASK=$ForemanNETMASK" >> variables.sh
echo "export ForemanGW=$ForemanGW" >> variables.sh
echo "export ForemanDNSSERVER=$ForemanDNSSERVER" >> variables.sh