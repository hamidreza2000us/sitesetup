#this script setup very base system to be use as dns forwarder, 
#it also server as primary dns server before IDM is setup
#After host is setup is finished, setup IDM host and make is primary DNS server for other servers
#don't forget to use this host as IDM forwarder
#start with a fresh miniamal RH82 with at least 1 core, 512 MG memory, 20GB disk is enough 
#don't forget to 1- mount the installation DVD and 2- don't run any DHCP service in the current network
#do the following manually
#ip a sh
#systemctl stop NetworkManager
#ip a a 192.168.13.10/24 dev ens160
#ip route add default via 192.168.13.2 dev ens160
#echo "nameserver 192.168.13.2" >> /etc/resolve.conf
#-----------------------------------
#ssh to host
#upload Site01.tar to /root/

yum -y install git
git clone https://github.com/hamidreza2000us/sitesetup.git

curl https://raw.githubusercontent.com/hamidreza2000us/sitesetup/master/RH7-BaseSystem.sh -o RH7-BaseSystem.sh
sed -i '1s/^.*#/#/;s/\r$//' ~/RH7-BaseSystem.sh
bash ~/RH7-BaseSystem.sh 

curl https://raw.githubusercontent.com/hamidreza2000us/sitesetup/master/RH82-DNSMasqSetup.sh -o RH82-DNSMasqSetup.sh
sed -i '1s/^.*#/#/;s/\r$//' ~/RH82-DNSMasqSetup.sh
bash ~/RH82-DNSMasqSetup.sh

