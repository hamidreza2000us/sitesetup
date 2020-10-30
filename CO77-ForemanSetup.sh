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
OS=CentOS
major=7
minor=8.2003
################################################################installation#########################################################################
#########################package install############################
#yum install -y yum-utils 
#yum -y localinstall https://yum.theforeman.org/releases/2.1/el7/x86_64/foreman-release.rpm
#yum -y localinstall https://fedorapeople.org/groups/katello/releases/yum/3.16/katello/el7/x86_64/katello-repos-latest.rpm
#yum -y localinstall https://yum.puppet.com/puppet6-release-el-7.noarch.rpm
#yum -y install epel-release centos-release-scl-rh
#yum -y install foreman-release-scl
#yum -y install katello foreman-proxy
#yum install -y https://yum.theforeman.org/client/latest/el7/x86_64/foreman-client-release-2.1.1-1.el7.noarch.rpm

yum install -y yum-utils 
yum -y localinstall https://yum.theforeman.org/releases/2.0/el7/x86_64/foreman-release.rpm
yum -y localinstall https://fedorapeople.org/groups/katello/releases/yum/3.15/katello/el7/x86_64/katello-repos-latest.rpm
yum -y localinstall https://yum.puppet.com/puppet6-release-el-7.noarch.rpm
yum -y localinstall https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install foreman-release-scl
yum install -y https://yum.theforeman.org/client/latest/el7/x86_64/foreman-client-release.rpm
yum -y install katello foreman-proxy
yum -y install  puppet-agent-oauth

#################realm config#######################
echo -e "$idmpass" | foreman-prepare-realm $idmuser foremanuser

/usr/bin/cp -f /root/freeipa.keytab /etc/foreman-proxy
chown foreman-proxy:foreman-proxy /etc/foreman-proxy/freeipa.keytab
/usr/bin/cp  -f /etc/ipa/ca.crt /etc/pki/ca-trust/source/anchors/ipa.crt
update-ca-trust enable
update-ca-trust
#######################firewall config##############################
if  [  $( firewall-cmd --query-service=RH-Satellite-6) == 'no'  ] ; then firewall-cmd --permanent --add-service=RH-Satellite-6 ; fi
firewall-cmd --reload
########################installation#############################
foreman-installer --scenario katello \
--foreman-initial-organization behsa \
--foreman-cli-foreman-url "https://${domain}" \
--foreman-cli-username admin \
--foreman-cli-password ${pass}  --foreman-initial-admin-password ${pass} 

foreman-installer  --foreman-proxy-realm true --foreman-proxy-realm-principal foremanuser@$idmrealm 

foreman-installer --enable-foreman-plugin-bootdisk   --enable-foreman-plugin-discovery   --enable-foreman-plugin-setup  \
--enable-foreman-plugin-ansible --enable-foreman-plugin-templates  --enable-foreman-cli \
--enable-foreman-cli-discovery --enable-foreman-cli-openscap --enable-foreman-cli-remote-execution --enable-foreman-cli-tasks \
--enable-foreman-cli-templates  --enable-foreman-cli-ansible --enable-foreman-proxy --enable-foreman-proxy-plugin-ansible  \
--enable-foreman-proxy-plugin-discovery  --enable-foreman-proxy-plugin-remote-execution-ssh \
--foreman-plugin-tasks-automatic-cleanup true --foreman-proxy-http true \
--foreman-proxy-bmc true \
--foreman-proxy-plugin-discovery-install-images true \
--foreman-proxy-tftp true \
--foreman-proxy-tftp-managed true \
--foreman-proxy-tftp-servername ${domain} \
--enable-foreman-plugin-openscap --enable-foreman-proxy-plugin-openscap \
--enable-foreman-compute-vmware  --enable-foreman-compute-openstack

#/usr/sbin/foreman-rake apipie:cache:index

# foreman-installer \
# --foreman-proxy-dhcp true \
# --foreman-proxy-dhcp-interface $interface \
# --foreman-proxy-dhcp-managed true \
# --foreman-proxy-dhcp-range="$startip $endip" \
# --foreman-proxy-dhcp-nameservers $dns \
# --foreman-proxy-dhcp-gateway $gw 

#########################Global config##################
hammer settings set --name ansible_ssh_private_key_file --value /var/lib/foreman-proxy/ssh/id_rsa_foreman_proxy 
hammer settings set --name  default_pxe_item_global --value discovery
hammer template build-pxe-default
#########################ansible config##################
sed -i -e 's/^#callback_whitelist = timer, mail/callback_whitelist = foreman/g' /etc/ansible/ansible.cfg
echo "[callback_foreman]" >> /etc/ansible/ansible.cfg
echo "url = https://$domain" >> /etc/ansible/ansible.cfg
echo "ssl_cert = /etc/foreman-proxy/ssl_cert.pem" >> /etc/ansible/ansible.cfg
echo "ssl_key = /etc/foreman-proxy/ssl_key.pem" >> /etc/ansible/ansible.cfg
echo "verify_certs = /etc/foreman-proxy/ssl_ca.pem" >> /etc/ansible/ansible.cfg

#foreman-maintain packages install -y rhel-system-roles
#hammer ansible roles import --role-names rhel-system-roles.timesync --proxy-id 1
#hammer ansible variables create --variable timesync_ntp_servers --variable-type array --override true \
#--default-value  "[{\"hostname\":\"$idmhost\"}]" --ansible-role  rhel-system-roles.timesync --hidden-value false


#########################ldap config##################
hammer auth-source ldap create --name $idmhost --host $idmhost --server-type free_ipa \
--account $idmuser --account-password "$idmpass" --base-dn $idmdn  --onthefly-register true \
--attr-login uid  --attr-firstname givenName --attr-lastname sn --attr-mail mail
hammer realm create --name $idmrealm --realm-type FreeIPA --realm-proxy-id 1 --organization-id 1
#########################lifecycle config##################
hammer lifecycle-environment create  --description "dev"  --name dev  --label dev --organization-id 1 --prior Library
hammer lifecycle-environment create  --description "qa"  --name qa  --label qa --organization-id 1 --prior dev
hammer lifecycle-environment create  --description "prod"  --name prod  --label prod --organization-id 1 --prior qa
#foreman-maintain service restart
################################################################basic media#########################################################################
#########################network config##################
hammer domain update --name $domainname --organization-id 1
#hammer subnet create --name $subnetname --network $network --mask $netmask --gateway $gw  \
#--dns-primary $dns --ipam DHCP --boot-mode DHCP --from $startip --to $endip  \
#--dhcp $domain  --tftp $domain --discovery-id 1 --httpboot-id 1 --domains $domainname --organization-id 1

hammer subnet create --name $subnetname --network $network --mask $netmask --gateway $gw  \
--dns-primary $dns --tftp $domain --discovery-id 1 --httpboot-id 1 --domains $domainname --organization-id 1
#########################medium config##################OK

mount -o ro /dev/cdrom /mnt/cdrom
mkdir -p /var/www/html/pub/media/
/usr/bin/cp -rf /mnt/cdrom /var/www/html/pub/media
mv /var/www/html/pub/media/cdrom /var/www/html/pub/media/$OS$major.$minor
curl -o /var/www/html/pub/media/$OS$major.$minor/images/boot.iso http://mirror.centos.org/centos/7/os/x86_64/images/boot.iso
restorecon -Rv /var/www/html/pub/media/$OS$major.$minor
hammer product create --name $OS --label $OS --organization-id 1
hammer medium create --name $OS$major.$minor --os-family Redhat --path http://$domain/pub/media/$OS$major.$minor --organization-id 1
#########################repository config##################OK
hammer repository   create  --name $OS$major.$minor    --content-type yum  --organization-id 1  \
--product $OS --url http://$domain/pub/media/$OS$major.$minor --download-policy immediate --mirror-on-sync false
hammer repository synchronize  --organization-id 1 --product $OS  --name $OS$major.$minor #--async

hammer repository   create  --name foreman-client  --content-type yum  --organization-id 1 \
--product $OS --url https://yum.theforeman.org/client/2.1/el7/x86_64/ --download-policy immediate --mirror-on-sync false
hammer repository synchronize  --organization-id 1 --product $OS  --name foreman-client #--async
#########################os config##################Ok-SoSO (why PXElinux?)
hammer os create --architectures x86_64 --name $OS --media $OS$major.$minor --partition-tables "Kickstart default" --major $major --minor $minor \
--provisioning-templates "PXELinux global default" --family "Redhat"
hammer os update --title "$OS $major.$minor" --media $OS$major.$minor
hammer template add-operatingsystem --name "PXELinux global default" --operatingsystem "$OS $major.$minor"
 
#########################contentview config##################   OK
hammer content-view create --name contentview01 --label contentview01 --organization-id 1 
hammer content-view add-repository --name contentview01 --repository $OS$major.$minor --organization-id 1 
hammer content-view add-repository --name contentview01 --repository foreman-client --organization-id 1
hammer content-view publish --name contentview01 --organization-id 1 #--async
hammer content-view  version promote --organization-id 1  --content-view contentview01 --to-lifecycle-environment dev

hammer activation-key create --name mykey01 --organization-id 1 --lifecycle-environment Library --content-view contentview01
hammer activation-key add-subscription --name mykey01 --subscription $OS --organization-id 1

#########################ansible config##################   OK
ansible-galaxy install hamidreza2000us.chrony -p /usr/share/ansible/roles/
hammer ansible roles import --role-names hamidreza2000us.chrony --proxy-id 1
ansible-galaxy install hamidreza2000us.motd -p /usr/share/ansible/roles/
hammer ansible roles import --role-names hamidreza2000us.motd --proxy-id 1
hammer ansible variables import --proxy-id 1
hammer ansible variables update --override true  --variable ntpserver --variable-type string  \
 --default-value "$idmhost" --ansible-role  hamidreza2000us.chrony  --hidden-value false  --name ntpserver
#########################hostgroup config##################  OK 
hammer hostgroup create --name hostgroup01 --lifecycle-environment Library   \
--architecture x86_64 --root-pass $newsyspass --organization-id 1 \
--operatingsystem "$OS $major.$minor" --medium $OS$major.$minor --partition-table "Kickstart default"  \
--pxe-loader 'PXELinux BIOS'   --domain $domainname  --subnet $subnetname    \
--content-view contentview01 --content-source $domain --realm $idmrealm 
#########################hostgroup parameter##################   OK
hammer hostgroup set-parameter --hostgroup hostgroup01 --name freeipa_server --parameter-type string --value $idmhost
hammer hostgroup set-parameter --hostgroup hostgroup01 --name freeipa_domain --parameter-type string --value $idmrealm
#hammer hostgroup ansible-roles assign --name hostgroup01 --ansible-roles rhel-system-roles.timesync 
#hammer hostgroup ansible-roles assign --name hostgroup01 --ansible-roles "hamidreza2000us.chrony,hamidreza2000us.motd"
hammer hostgroup set-parameter --hostgroup hostgroup01  --name package_upgrade --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup hostgroup01  --name use-ntp --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup hostgroup01  --name time-zone --parameter-type string --value Asia/Tehran
hammer hostgroup set-parameter --hostgroup hostgroup01  --name ntp-server --parameter-type string --value $dns

pubkey=$(curl -k https://$domain:9090/ssh/pubkey)
hammer hostgroup set-parameter --hostgroup hostgroup01  --name remote_execution_ssh_keys  --parameter-type array --value "[$pubkey]"
hammer hostgroup set-parameter --hostgroup hostgroup01  --name redhat_install_agent --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup hostgroup01  --name subscription_manager --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup hostgroup01  --name redhat_install_host_tools --parameter-type boolean --value true
hammer hostgroup set-parameter --hostgroup hostgroup01  --name atomic --parameter-type boolean --value false
hammer hostgroup set-parameter --hostgroup hostgroup01  --name subscription_manager_certpkg_url --parameter-type string --value https://$domain/pub/katello-ca-consumer-latest.noarch.rpm
hammer hostgroup set-parameter --hostgroup hostgroup01  --name kt_activation_keys --parameter-type string --value mykey01
hammer hostgroup set-parameter --hostgroup hostgroup01  --name freeipa_server --parameter-type string --value $idmhost
hammer hostgroup set-parameter --hostgroup hostgroup01  --name freeipa_domain --parameter-type string --value $idmrealm
hammer hostgroup set-parameter --hostgroup hostgroup01  --name realm.realm_type --parameter-type string --value FreeIPA
hammer hostgroup set-parameter --hostgroup hostgroup01  --name enable-epel --parameter-type boolean --value false
######################################################################################################


#########################scap config################## Ok (change scap profile to centos)
#ansible-galaxy install giovtorres.postfix-null-client -p /usr/share/ansible/roles/
ansible-galaxy  install theforeman.foreman_scap_client -p /usr/share/ansible/roles/
foreman-rake foreman_openscap:bulk_upload:default
hammer ansible roles import --role-names theforeman.foreman_scap_client --proxy-id 1
hammer ansible variables import --proxy-id 1
hammer policy create --organization-id 1 --period monthly --day-of-month 1 --deploy-by ansible --hostgroups hostgroup01 --name policy01  --scap-content-profile-id 5  --scap-content-id 2
hammer hostgroup ansible-roles assign --name hostgroup01 --ansible-roles "hamidreza2000us.chrony,hamidreza2000us.motd,theforeman.foreman_scap_client"
hammer ansible variables update --override true  --variable foreman_scap_client_server --variable-type string \
--default-value "$domain" --ansible-role  theforeman.foreman_scap_client  --hidden-value false  --name foreman_scap_client_server
###############################################Templates###############################################OK (with some fixes)
cat >  /tmp/packages << EOF
subscription-manager
ipa-client
bash-completion
tuned
lsof
nmap
tmux
tcpdump
telnet
unzip
vim
yum-utils
bind-utils
sysstat
xorg-x11-xauth 
dbus-x11
splunkforwarder
EOF
hammer template create --name "Kickstart default custom packages" --type snippet --file /tmp/packages --organization-id 1
hammer template create --name "Kickstart scap custom packages" --type snippet --file /tmp/packages --organization-id 1

cat >  /tmp/post << EOF
sed -i 's/crashkernel=auto//g' /etc/default/grub
grub2-mkconfig > /boot/grub2/grub.cfg
systemctl disable kdump.service
systemctl mask kdump.service

ls -d /etc/yum.repos.d/* | grep -v redhat.repo |xargs -I % mv % %.bkp
EOF
hammer template create --name "Kickstart default custom post" --type snippet --file /tmp/post --organization-id 1
hammer template create --name "Kickstart scap custom post" --type snippet --file /tmp/post --organization-id 1

hammer template dump --name "Kickstart default" > /tmp/kickdefaulttemplate
sed  -i '/^skipx.*/a \\n%addon org_fedora_oscap\ncontent-type = scap-security-guide\nprofile = pci-dss\n%end' /tmp/kickdefaulttemplate
hammer template create --file /tmp/kickdefaulttemplate --name "Kickstart scap" --type "provision" --organization-id 1
hammer template add-operatingsystem --name "Kickstart scap" --operatingsystem "$OS $major.$minor"
#osid=$(hammer --csv os list | grep "$OS $major.$minor," | awk -F, {'print $1'})
#SATID=$(hammer --csv template list  | grep "provision" | grep ",Kickstart scap," | cut -d, -f1)
#hammer os set-default-template --id $osid --provisioning-template-id $SATID

hammer host create --name myhost01 --hostgroup hostgroup01 --content-source $domain \
 --medium $OS$major.$minor --partition-table "Kickstart default" --pxe-loader "PXELinux BIOS"  \
 --organization-id 1  --location "Default Location" --interface mac=00:0C:29:2B:7B:C8 \
 --build true --enabled true --managed true
#--openscap-proxy-id 1

###############################
#curl --insecure --output katello-ca-consumer-latest.noarch.rpm  https://$domain/pub/katello-ca-consumer-latest.noarch.rpm
#yum localinstall -y katello-ca-consumer-latest.noarch.rpm
#subscription-manager register --org="Default_Organization" --activationkey=mykey01
#yum -y install katello-host-tools
#yum -y install katello-host-tools-tracer
#yum -y install katello-agent

# ansible-galaxy install robertdebock.auditd  -p /usr/share/ansible/roles/
# ansible-galaxy install robertdebock.rsyslog  -p /usr/share/ansible/roles/

###############################upload splunk packages###############################
mkdir -p /var/www/html/pub/packages/Splunk
curl -o /var/www/html/pub/packages/Splunk/splunk-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm \
https://download.splunk.com/products/splunk/releases/8.1.0/linux/splunk-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm

curl -o /var/www/html/pub/packages/Splunk/splunkforwarder-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm \
https://download.splunk.com/products/universalforwarder/releases/8.1.0/linux/splunkforwarder-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm

hammer repository   create  --name Splunk  --content-type yum  --organization-id 1 \
--product $OS --download-policy immediate --mirror-on-sync false

hammer repository upload-content --name Splunk --organization-id 1 --product CentOS \
--path /var/www/html/pub/packages/Splunk/splunk-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm

hammer repository upload-content --name Splunk --organization-id 1 --product CentOS \
--path /var/www/html/pub/packages/Splunk/splunkforwarder-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm

hammer content-view add-repository --name contentview01 --repository Splunk --organization-id 1
hammer content-view publish --name contentview01 --organization-id 1 #--async
contentVersion=$( hammer --output csv content-view version  list --content-view contentview01  --organization-id 1 | grep Library | awk -F, '{print $3}')
hammer content-view  version promote --organization-id 1  --content-view contentview01 --to-lifecycle-environment dev --version $contentVersion