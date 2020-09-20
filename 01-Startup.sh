#this script setup a base system to be use as dns forwarder,
#it also server as primary dns server before IDM is setup
#######################################################################################
#PLEASE note the 0-INTRO.txt and excute the commands needed before running this script#
#######################################################################################
echo "We need some input for intial setup. Plase be patient for a few minutes"
curl https://raw.githubusercontent.com/hamidreza2000us/sitesetup/master/RH7-8-BaseParameters.sh -o ~/sitesetup-pre/RH7-8-BaseParameters.sh
curl https://raw.githubusercontent.com/hamidreza2000us/sitesetup/master/RH7-ForemanBaseSystem.sh -o ~/sitesetup-pre/RH7-ForemanBaseSystem.sh
curl https://raw.githubusercontent.com/hamidreza2000us/sitesetup/master/variables.sh -o ~/sitesetup-pre/variables.sh
bash ~/sitesetup-pre/RH7-8-BaseParameters.sh
source ~/sitesetup-pre/variables.sh
bash ~/sitesetup-pre/RH7-ForemanBaseSystem.sh
ssh-keygen -t rsa
ssh-copy-id root@$IDMIP
echo -e "\n\r\n\r\n\rThere is no other input from your side. So relax. this setup would takes hours to complete\n\r\n\r\n\r"
git clone https://github.com/hamidreza2000us/sitesetup.git
cp ~/sitesetup-pre/variables.sh ~/sitesetup/
bash ~/sitesetup/RH82-DNSMasqSetup.sh
scp -r ~/sitesetup root@$IDMIP:~/
ssh $IDMIP 02-IDMHostsetup.sh


