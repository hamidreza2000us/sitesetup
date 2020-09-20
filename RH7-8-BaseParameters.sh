#!/bin/bash
#This script get and set basic network information 
if [[ -f ~/sitesetup-pre/variables.sh ]]
then
  source ~/sitesetup-pre/variables.sh
fi

read -rp "IDM Hostname to use: ($IDMHOSTNAME): " choice; [[ -n "${choice}"  ]] &&  export IDMHOSTNAME="$choice"; 
read -rp "IDM IP to use: ($IDMIP): " choice; [[ -n "${choice}"  ]] &&  export IDMIP="$choice"; 
read -rp "IDM Netmask to use (just the number of bits): ($IDMNETMASK): " choice;[[ -n "${choice}"  ]] &&  export IDMNETMASK="$choice"; 
read -rp "IDM GW to use: ($IDMGW): " choice; [[ -n "${choice}"  ]] &&  export IDMGW="$choice";
read -rp "IDM domain to use: ($IDMDomain): " choice; [[ -n "${choice}"  ]] &&  export IDMDomain="$choice";
read -rp "IDM Realm to use: ($IDMRealm): " choice; [[ -n "${choice}"  ]] &&  export IDMRealm="$choice";
read -rp "IDM Password to use: ($IDMPass): " choice; [[ -n "${choice}"  ]] &&  export IDMPass="$choice";
read -rp "Foreman Hostname to use: ($ForemanHOSTNAME): " choice;[[ -n "${choice}"  ]] &&  export ForemanHOSTNAME="$choice";
read -rp "Foreman IP to use: ($ForemanIP): " choice; [[ -n "${choice}"  ]] &&  export ForemanIP="$choice";
read -rp "Foreman Netmask to use (just the number of bits): ($ForemanNETMASK): " choice;	[[ -n "${choice}"  ]] &&  export ForemanNETMASK="$choice";
read -rp "Foreman GW to use: ($ForemanGW): " choice; [[ -n "${choice}"  ]] &&  export ForemanGW="$choice";
read -rp "Foreman Global DNS to use: ($ForemanDNSSERVER): " choice;	[[ -n "${choice}"  ]] &&  export ForemanDNSSERVER="$choice";

echo "export IDMHOSTNAME=$IDMHOSTNAME" > ~/sitesetup-pre/variables.sh
echo "export IDMIP=$IDMIP" >> ~/sitesetup-pre/variables.sh
echo "export IDMNETMASK=$IDMNETMASK" >> ~/sitesetup-pre/variables.sh
echo "export IDMGW=$IDMGW" >> ~/sitesetup-pre/variables.sh
echo "export IDMDomain=$IDMDomain" >> ~/sitesetup-pre/variables.sh
echo "export IDMRealm=$IDMRealm" >> ~/sitesetup-pre/variables.sh
echo "export IDMPass=$IDMPass" >> ~/sitesetup-pre/variables.sh
echo "export ForemanHOSTNAME=$ForemanHOSTNAME" >> ~/sitesetup-pre/variables.sh
echo "export ForemanIP=$ForemanIP" >> ~/sitesetup-pre/variables.sh
echo "export ForemanNETMASK=$ForemanNETMASK" >> ~/sitesetup-pre/variables.sh
echo "export ForemanGW=$ForemanGW" >> ~/sitesetup-pre/variables.sh
echo "export ForemanDNSSERVER=$ForemanDNSSERVER" >> ~/sitesetup-pre/variables.sh