#This script get some resources and setup idm and chrony service to be use by other services
#The DNS server is also setup and act as primary dns server for the domain
#The system requires RHEL 8.2 with at least 8GB of memory 20GB harddisk and one interface
#Installation DVD should be mounted
#ip a sh
#ip a a 192.168.13.11/24 dev ens160
#ip route add default via 192.168.13.2 dev ens160

######?????????????find a way to disable dnssec -> it cause problem with forward requests
bash ~/sitesetup/RH8-IDMBaseSystem.sh
bash ~/sitesetup/RH7-8-SetupChrony.sh
bash ~/sitesetup/RH82-IDMSetup.sh




