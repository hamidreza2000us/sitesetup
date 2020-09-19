#!/bin/bash
#This script set hostname, convert DHCP IP address to permenant, configure dns server, mount cdrom, setup repository

export HOSTNAME="$(hostname)"
export IP=${IP:="$(ip route get 8.8.8.8 | awk '{print $7; exit}')"}
export GW=${GW:="$(ip route get 8.8.8.8 | awk '{print $3; exit}')"}
export ENS=${ENS:="$(ip a sh | grep ": ens" | awk '{print $2}' | sed -e "s/://g")"}
export NETMASK=${NETMASK:="$(ip a sh | grep "ens" | grep "inet" |  awk '{print $2}' |  awk -F/ '{print $2}')"}
export DNSSERVER=${DNSSERVER:="192.168.13.11"}

read -rp "Hostname to use: ($HOSTNAME): " choice;
       if [ "$choice" != "" ] ; then
               export HOSTNAME="$choice";
       fi

read -rp "IP to use: ($IP): " choice;
       if [ "$choice" != "" ] ; then
               export IP="$choice";
       fi

read -rp "NETMASK to use: ( $NETMASK ): " choice;
       if [ "$choice" != "" ] ; then
               export NETMASK="$choice";
       fi

read -rp "Gateway to use: ( $GW ): " choice;
       if [ "$choice" != "" ] ; then
               export GW="$choice";
       fi

read -rp "DNSServer to use: ($DNSSERVER): " choice;
       if [ "$choice" != "" ] ; then
               export DNSSERVER="$choice";
       fi

read -rp "Interface to use: ($ENS): " choice;
       if [ "$choice" != "" ] ; then
               export ENS="$choice";
       fi


echo "******"
echo "* Your Hostname is $HOSTNAME "
echo "* Your IP is $IP "
echo "* Your NETMASK is $NETMASK "
echo "* Your GW is $GW "
echo "* Your DNSServer is $DNSSERVER "
echo "* Your Interface is $ENS "
echo "******"

hostnamectl set-hostname $HOSTNAME
nmcli con add con-name fixed ifname $ENS type ethernet connection.autoconnect yes ipv4.method manual ipv4.dns $DNSSERVER ipv4.gateway $GW ipv4.addresses $IP/$NETMASK
nmcli con up fixed
nmcli con sh | grep " --" | awk '{print $1}' | xargs nmcli con del

if [ ! -d /mnt/cdrom ] ; then mkdir /mnt/cdrom ; fi
if [ $(df | grep /mnt/cdrom | grep /dev/sr0 | wc -l) == 0 ] 
then 
  mount -o ro /dev/cdrom /mnt/cdrom
fi

cat <<EOD > /etc/yum.repos.d/cd.repo
[cd]
name=cd
baseurl=file:///mnt/cdrom
gpgcheck=0
EOD

yum install -y bash-completion tuned chrony lsof nmap tmux tcpdump telnet unzip vim yum-utils bind-utils sysstat

if [ $(systemctl is-enabled chronyd) == 'disabled'  ]
then
  systemctl enable chronyd 
fi
systemctl restart chronyd

echo "alias vi=vim" >> /root/.bash_profile
