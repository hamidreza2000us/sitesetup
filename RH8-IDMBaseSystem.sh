#!/bin/bash
#This script set hostname, convert DHCP IP address to permenant, configure dns server, mount cdrom, setup repository
if [[ -f ~/sitesetup/variables.sh ]]
then
  source ~/sitesetup/variables.sh
fi

Fault=false
IP=${IP:="$(ip route get 8.8.8.8 | awk '{print $7; exit}')"}
if [[ $IDMIP != $IP ]] ; then Fault=true ; fi
NETMASK=${NETMASK:="$(ip a sh | grep "ens" | grep "inet" |  awk '{print $2}' |  awk -F/ '{print $2}')"}
if [[ $IDMNETMASK != $NETMASK ]] ; then Fault=true ; fi
GW=${GW:="$(ip route get 8.8.8.8 | awk '{print $3; exit}')"}
if [[ $IDMGW != $GW ]] ; then Fault=true ; fi
ENS=${ENS:="$(ip a sh | grep -B2 $IDMIP |grep ": ens" | awk '{print $2}' | sed -e "s/://g")"}
if [[ -z $ENS ]] ; then Fault=true ; fi
if [[ $Fault == true ]]
then
	echo "There is a problem between running ip configurations and setup variables"
	echo "Setup can't continue. Please resolve the issue and run it again"
	exit
fi

hostnamectl set-hostname $IDMHOSTNAME
nmcli con add con-name fixed ifname $ENS type ethernet connection.autoconnect yes ipv4.method manual ipv4.dns $ForemanIP ipv4.gateway $IDMGW ipv4.addresses $IDMIP/$IDMNETMASK 
nmcli con up fixed
nmcli --fields UUID,TYPE,DEVICE  con sh | grep " --" | awk '{print $1}' | xargs nmcli con del

if [ ! -d /mnt/cdrom ] ; then mkdir /mnt/cdrom ; fi
if [ $(df | grep /mnt/cdrom | grep /dev/sr0 | wc -l) == 0 ] 
then 
  mount -o ro /dev/cdrom /mnt/cdrom
fi

cat <<EOD > /etc/yum.repos.d/cd.repo
[AppStrem]
name=appstrem
baseurl=file:///mnt/cdrom/AppStream
gpgcheck=0

[BaseOS]
name=baseos
baseurl=file:///mnt/cdrom/BaseOS/
gpgcheck=0
EOD

yum clean all
yum install -y bash-completion tuned chrony lsof nmap tmux tcpdump telnet unzip vim yum-utils bind-utils sysstat

if [ $(systemctl is-enabled chronyd) == 'disabled'  ]
then
  systemctl enable chronyd 
fi
systemctl restart chronyd

echo "alias vi=vim" >> /root/.bash_profile
