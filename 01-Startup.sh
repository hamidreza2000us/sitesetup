#this script setup a base system to be use as dns forwarder,
#it also server as primary dns server before IDM is setup
#######################################################################################
#PLEASE note the 0-INTRO.txt and excute the commands needed before running this script#
#######################################################################################
echo "We need some input for intial setup. Plase be patient for a few minutes"
curl https://raw.githubusercontent.com/hamidreza2000us/sitesetup/master/RH7-8-BaseParameters.sh -o ~/sitesetup/RH7-8-BaseParameters.sh
curl https://raw.githubusercontent.com/hamidreza2000us/sitesetup/master/RH7-BaseSystem.sh -o ~/sitesetup/RH7-BaseSystem.sh
bash ~/sitesetup/RH7-8-BaseParameters.sh
bash ~/sitesetup/RH7-ForemanBaseSystem.sh
ssh-keygen -t rsa
ssh-copy-id root@
echo "There is no other input from your side. So relax. this setup would takes hours to complete"
git clone https://github.com/hamidreza2000us/sitesetup.git
bash ~/sitesetup/RH82-DNSMasqSetup.sh

