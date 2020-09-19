#this script setup very base system to be use as dns forwarder, 
#it also server as primary dns server before IDM is setup
#After host is setup is finished, setup IDM host and make is primary DNS server for other servers
#don't forget to use this host as IDM forwarder
#start with a fresh miniamal RH82 with at least 1 core, 512 MG memory, 20GB disk is enough 
#don't forget to 1- mount the installation DVD and 2- don't run any DHCP service in the current network
#do the following manually
#ip a sh
#ip a a 192.168.13.10/24 dev ens160
#ip route add default via 192.168.13.2 dev ens160
#-----------------------------------
#ssh to host
#upload Site01.tar to /root/
if [ -f ~/Site01.tar ] 
then 
  tar -xvf ~/Site01.tar
  #copy and paste RH8-BaseSystem.sh to /root/
  sed -i '1s/^.*#/#/;s/\r$//' ~/Site01/RH8-BaseSystem.sh
  bash ~/Site01/RH8-BaseSystem.sh
  #copy RH82-DNSMasqSetup.sh to /root/
  sed -i '1s/^.*#/#/;s/\r$//' ~/Site01/RH82-DNSMasqSetup.sh
  bash ~/Site01/RH82-DNSMasqSetup.sh
  #copy RH82-HTTPDSetup.sh
  sed -i '1s/^.*#/#/;s/\r$//' ~/Site01/RH82-HTTPDSetup.sh
  bash ~/Site01/RH82-HTTPDSetup.sh
  mv Site01 /srv/myhost/www/
  restorecon -Rv /srv/myhost/www/
fi



