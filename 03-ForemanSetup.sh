#this system requires Centos 7.8 
#requires at least 8GB of memory to install
#installation DVD should be mounted
#ip a sh
#ip a a 192.168.13.11/24 dev ens160
#ip route add default via 192.168.13.2 dev ens160
mkdir /root/Site01
#pull the script below:
# curl http://192.168.13.10/Site01/03-ForemanSetup.sh -o /root/Site01/03-ForemanSetup.sh
# sed -i '1s/^.*#/#/;s/\r$//' /root/Site01/03-ForemanSetup.sh
# bash /root/Site01/03-ForemanSetup.sh

curl http://192.168.13.10/Site01/RH7-BaseSystem.sh -o /root/Site01/RH7-BaseSystem.sh
sed -i '1s/^.*#/#/;s/\r$//' /root/Site01/RH7-BaseSystem.sh
bash /root/Site01/RH7-BaseSystem.sh

curl http://192.168.13.10/Site01/RH7-8-SetupChronyClient.sh -o /root/Site01/RH7-8-SetupChronyClient.sh
sed -i '1s/^.*#/#/;s/\r$//' /root/Site01/RH7-8-SetupChronyClient.sh
bash /root/Site01/RH7-8-SetupChronyClient.sh

curl http://192.168.13.10/Site01/CO77-IDMRegister.sh -o /root/Site01/CO77-IDMRegister.sh
sed -i '1s/^.*#/#/;s/\r$//' /root/Site01/CO77-IDMRegister.sh
bash /root/Site01/CO77-IDMRegister.sh

curl http://192.168.13.10/Site01/CO77-ForemanSetup.sh -o /root/Site01/CO77-ForemanSetup.sh
sed -i '1s/^.*#/#/;s/\r$//' /root/Site01/CO77-ForemanSetup.sh
bash /root/Site01/CO77-ForemanSetup.sh



