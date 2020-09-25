source ~/sitesetup/variables.sh
domain=$ForemanHOSTNAME
domainname=$IDMDomain
pass=$ForemanPass

gw=$ForemanGW
dns=$IDMIP
interface=$(nmcli dev | grep connected | awk  '{print $1}')
subnetname=$(echo ${ForemanIP} | awk -F. '{print "subnet"$3}')
IPRange=$(echo ${ForemanIP} | awk -F. '{print $1"."$2"."$3}')
startip=$IPRange.50
endip=$IPRange.100
network=$IPRange.0
netmask=255.255.255.0

idmhost=$IDMHOSTNAME
idmpass=$IDMPass
idmdn=$(echo $IDMDomain | awk -F. '{print "dc="$1",dc="$2}')
idmdn="dc=myhost,dc=com"
idmrealm=$IDMRealm

#default Values
idmuser=admin
newsyspass=Iahoora@123
#can read these value from .treeinfo
OS=Redhat
major=7
minor=8
contentview=content-$OS$major-$minor
keyname=key-$OS$major.$minor
hostgroup=hostgroup-$OS$major.$minor
#########################medium config##################OK

mount -o ro /dev/cdrom /mnt/cdrom
mkdir -p /var/www/html/pub/media/
/usr/bin/cp -rf /mnt/cdrom /var/www/html/pub/media
mv /var/www/html/pub/media/cdrom /var/www/html/pub/media/$OS$major.$minor
#curl -o /var/www/html/pub/media/$OS$major.$minor/images/boot.iso http://mirror.centos.org/centos/7/os/x86_64/images/boot.iso
restorecon -Rv /var/www/html/pub/media/$OS$major.$minor
hammer product create --name $OS --label $OS --organization-id 1
hammer medium create --name $OS$major.$minor --os-family Redhat --path http://$domain/pub/media/$OS$major.$minor --organization-id 1
#########################repository config##################OK
hammer repository   create  --name $OS$major.$minor    --content-type yum  --organization-id 1  \
--product $OS --url http://$domain/pub/media/$OS$major.$minor --download-policy immediate --mirror-on-sync false
hammer repository synchronize  --organization-id 1 --product $OS  --name $OS$major.$minor #--async

hammer repository   create  --name rh-foreman-client  --content-type yum  --organization-id 1 \
--product $OS --url http://192.168.13.120/pub/export/sat-tools/ --download-policy immediate --mirror-on-sync false
#hammer repository synchronize  --organization-id 1 --product $OS  --name rh-foreman-client #--async
#########################os config##################Ok-SoSO (why PXElinux?)
hammer os create --architectures x86_64 --name $OS --media $OS$major.$minor --partition-tables "Kickstart default" --major $major --minor $minor \
--provisioning-templates "PXELinux global default" --family "Redhat"
hammer os update --title "$OS $major.$minor" --media $OS$major.$minor
hammer template add-operatingsystem --name "PXELinux global default" --operatingsystem "$OS $major.$minor"
 
#########################contentview config##################   OK
hammer content-view create --name $contentview --label $contentview --organization-id 1 
hammer content-view add-repository --name $contentview --repository $OS$major.$minor --organization-id 1 
hammer content-view add-repository --name $contentview --repository rh-foreman-client --organization-id 1
hammer content-view publish --name $contentview --organization-id 1 #--async
hammer content-view  version promote --organization-id 1  --content-view $contentview --to-lifecycle-environment dev

hammer activation-key create --name $keyname --organization-id 1 --lifecycle-environment Library --content-view $contentview
hammer activation-key add-subscription --name $keyname --subscription $OS --organization-id 1

#########################hostgroup config##################  OK 
hammer hostgroup create --name $hostgroup --lifecycle-environment Library   \
--architecture x86_64 --root-pass $newsyspass --organization-id 1 \
--operatingsystem "$OS $major.$minor" --medium $OS$major.$minor --partition-table "Kickstart default"  \
--pxe-loader 'PXELinux BIOS'   --domain $domainname  --subnet $subnetname    \
--content-view $contentview --content-source $domain --realm $idmrealm 
#########################hostgroup parameter##################   OK
hammer hostgroup set-parameter --hostgroup $hostgroup --name freeipa_server --parameter-type string --value $idmhost
hammer hostgroup set-parameter --hostgroup $hostgroup --name freeipa_domain --parameter-type string --value $idmrealm
#hammer hostgroup ansible-roles assign --name $hostgroup --ansible-roles rhel-system-roles.timesync 
#hammer hostgroup ansible-roles assign --name $hostgroup --ansible-roles "hamidreza2000us.chrony,hamidreza2000us.motd"
hammer hostgroup set-parameter --hostgroup $hostgroup  --name package_upgrade --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup $hostgroup  --name use-ntp --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup $hostgroup  --name time-zone --parameter-type string --value Asia/Tehran
hammer hostgroup set-parameter --hostgroup $hostgroup  --name ntp-server --parameter-type string --value $dns

pubkey=$(curl -k https://$domain:9090/ssh/pubkey)
hammer hostgroup set-parameter --hostgroup $hostgroup  --name remote_execution_ssh_keys  --parameter-type array --value "[$pubkey]"
hammer hostgroup set-parameter --hostgroup $hostgroup  --name redhat_install_agent --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup $hostgroup  --name subscription_manager --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup $hostgroup  --name redhat_install_host_tools --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup $hostgroup  --name atomic --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup $hostgroup  --name subscription_manager_certpkg_url --parameter-type string --value https://$domain/pub/katello-ca-consumer-latest.noarch.rpm
hammer hostgroup set-parameter --hostgroup $hostgroup  --name kt_activation_keys --parameter-type string --value $keyname
hammer hostgroup set-parameter --hostgroup $hostgroup  --name freeipa_server --parameter-type string --value $idmhost
hammer hostgroup set-parameter --hostgroup $hostgroup  --name freeipa_domain --parameter-type string --value $idmrealm
hammer hostgroup set-parameter --hostgroup $hostgroup  --name realm.realm_type --parameter-type string --value FreeIPA
hammer hostgroup set-parameter --hostgroup $hostgroup  --name enable-epel --parameter-type boolean --value false
######################################################################################################
hammer hostgroup ansible-roles assign --name $hostgroup --ansible-roles "hamidreza2000us.chrony,hamidreza2000us.motd,theforeman.foreman_scap_client"
###############################################Templates###############################################OK (with some fixes)

hammer policy create --organization-id 1 --period monthly --day-of-month 1 --deploy-by ansible --hostgroups $hostgroup  --name policy-rh7\
 --scap-content-profile-id 36  --scap-content-id 7
hammer hostgroup ansible-roles assign --name $hostgroup --ansible-roles "hamidreza2000us.chrony,hamidreza2000us.motd,theforeman.foreman_scap_client"