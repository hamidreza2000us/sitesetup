domain=foreman3.myhost.com
domainname=myhost.com
pass=ahoora
interface=ens33
subnetname=subnet13
startip=192.168.13.50
endip=192.168.13.100
gw=192.168.13.2
dns=192.168.13.11
network=192.168.13.0
netmask=255.255.255.0
idmhost=idm.myhost.com
idmuser=admin
idmpass=Iahoora@123
idmdn="dc=myhost ,dc=com"
idmrealm=MYHOST.COM
newsyspass=Iahoora@123
OS=RH
major=7
minor=7
################################################################installation#########################################################################
#########################package install############################
yum install -y yum-utils 
yum -y localinstall https://yum.theforeman.org/releases/2.1/el7/x86_64/foreman-release.rpm
yum -y localinstall https://fedorapeople.org/groups/katello/releases/yum/3.16/katello/el7/x86_64/katello-repos-latest.rpm
yum -y localinstall https://yum.puppet.com/puppet6-release-el-7.noarch.rpm
yum -y install epel-release centos-release-scl-rh
yum -y install foreman-release-scl
yum -y install katello foreman-proxy
yum install -y https://yum.theforeman.org/client/latest/el7/x86_64/foreman-client-release-2.1.1-1.el7.noarch.rpm
#################realm config#######################
echo -e "$idmpass" | foreman-prepare-realm $idmuser foremanuser
cp -f /root/freeipa.keytab /etc/foreman-proxy
chown foreman-proxy:foreman-proxy /etc/foreman-proxy/freeipa.keytab
cp  -f /etc/ipa/ca.crt /etc/pki/ca-trust/source/anchors/ipa.crt
update-ca-trust enable
update-ca-trust
#######################firewall config##############################
if  [  $( firewall-cmd --query-service=RH-Satellite-6) == 'no'  ] ; then firewall-cmd --permanent --add-service=RH-Satellite-6 ; fi
firewall-cmd --reload
########################installation#############################
foreman-installer --scenario katello --foreman-proxy-realm true --foreman-proxy-realm-principal foremanuser@$idmrealm \
--foreman-initial-organization myorg \
--foreman-cli-foreman-url "https://$domain" \
--foreman-cli-username admin \
--foreman-cli-password $pass  --foreman-initial-admin-password $pass \
--enable-foreman-plugin-bootdisk   --enable-foreman-plugin-discovery   --enable-foreman-plugin-setup  \
--enable-foreman-plugin-ansible --enable-foreman-plugin-templates  --enable-foreman-cli \
--enable-foreman-cli-discovery --enable-foreman-cli-openscap --enable-foreman-cli-remote-execution --enable-foreman-cli-tasks \
--enable-foreman-cli-templates  --enable-foreman-cli-ansible --enable-foreman-proxy --enable-foreman-proxy-plugin-ansible  \
--enable-foreman-proxy-plugin-discovery  --enable-foreman-proxy-plugin-remote-execution-ssh \
--foreman-plugin-tasks-automatic-cleanup true \
--foreman-proxy-bmc true \
--foreman-proxy-plugin-discovery-install-images true \
--foreman-proxy-dhcp true \
--foreman-proxy-dhcp-interface ens33 \
--foreman-proxy-dhcp-managed true \
--foreman-proxy-dhcp-range="$startip $endip" \
--foreman-proxy-dhcp-nameservers $dns \
--foreman-proxy-dhcp-gateway $gw \
--foreman-proxy-tftp true \
--foreman-proxy-tftp-managed true \
--foreman-proxy-tftp-servername $domain \
--enable-foreman-plugin-openscap --enable-foreman-proxy-plugin-openscap \
--enable-foreman-compute-vmware  --enable-foreman-compute-openstack

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

foreman-maintain packages install -y rhel-system-roles
hammer ansible roles import --role-names rhel-system-roles.timesync --proxy-id 1
hammer ansible variables create --variable timesync_ntp_servers --variable-type array --override true \
--default-value  "[{\"hostname\":\"$idmhost\"}]" --ansible-role  rhel-system-roles.timesync --hidden-value false

ansible-galaxy  install theforeman.foreman_scap_client -p /usr/share/ansible/roles/
foreman-rake foreman_openscap:bulk_upload:default
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
hammer subnet create --name $subnetname --network $network --mask $netmask --gateway $gw  \
--dns-primary $dns --ipam DHCP --boot-mode DHCP --from $startip --to $endip  \
--dhcp $domain  --tftp $domain --discovery-id 1 --httpboot-id 1 --template-id 1 --domains $domainname --organization-id 1
#########################medium config##################

mount -o ro /dev/cdrom /mnt/cdrom
mkdir -p /var/www/html/pub/media/
cp -r /mnt/cdrom /var/www/html/pub/media
mv /var/www/html/pub/media/cdrom /var/www/html/pub/media/$OS$major.$minor
restorecon -Rv /var/www/html/pub/media/$OS$major.$minor
hammer product create --name $OS --label $OS --organization-id 1
hammer medium create --name $OS$major.$minor --os-family Redhat --path http://$domain/pub/media/$OS$major.$minor --organization-id 1
#########################repository config##################
hammer repository   create  --name $OS$major.$minor    --content-type yum  --organization-id 1  \
--product $OS --url http://$domain/pub/media/$OS$major.$minor --download-policy immediate --mirror-on-sync false
hammer repository synchronize  --organization-id 1 --product $OS  --name $OS$major.$minor #--async
#########################os config##################
hammer os create --architectures x86_64 --name $OS --media $OS$major.$minor --partition-tables "Kickstart default" --major $major --minor $minor \
--provisioning-templates "PXELinux global default" --family "Redhat"
hammer template add-operatingsystem --name "PXELinux global default" --operatingsystem "$OS$major.$minor"
 
#########################contentview config##################   
hammer content-view create --name contentview01 --label contentview01 --organization-id 1 
hammer content-view add-repository --name contentview01 --repository $OS$major.$minor --organization-id 1 
hammer content-view publish --name contentview01 --organization-id 1 #--async
hammer content-view  version promote --organization-id 1  --content-view contentview01 --to-lifecycle-environment dev

hammer activation-key create --name mykey01 --organization-id 1 --lifecycle-environment Library --content-view contentview01
hammer activation-key add-subscription --name mykey01 --subscription $OS --organization-id 1

#########################hostgroup config##################   
hammer hostgroup create --name hostgroup01 --lifecycle-environment Library   \
--architecture x86_64 --root-pass $newsyspass --organization-id 1 \
--operatingsystem "myCent 7.7" --medium $OS$major.$minor --partition-table "Kickstart default"  \
--pxe-loader 'PXELinux BIOS'   --domain $domainname  --subnet $subnetname    \
--content-view contentview01 --content-source $domain --realm $idmrealm 
#########################hostgroup parameter##################   
hammer hostgroup set-parameter --hostgroup hostgroup01 --name freeipa_server --parameter-type string --value $idmhost
hammer hostgroup set-parameter --hostgroup hostgroup01 --name freeipa_domain --parameter-type string --value $idmrealm
hammer hostgroup ansible-roles assign --name hostgroup01 --ansible-roles rhel-system-roles.timesync 
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

 

###############################################Templates###############################################
cat >  /tmp/packages << EOF
bash-completion
tuned
chrony
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
EOF
hammer template create --name "MyKickstart01 custom packages" --type snippet --file /tmp/packages --organization-id 1

cat >  /tmp/post << EOF
#%addon com_redhat_kdump --disable
#%end
systemctl disable kdump.service
systemctl mask kdump.service
#ls -d /etc/yum.repos.d/* | grep -v redhat.repo |xargs -I % mv % %.bkp
EOF
hammer template create --name "MyKickstart01 custom post" --type snippet --file /tmp/post --organization-id 1

hammer template dump --name "Kickstart default" > /tmp/kickdefaulttemplate
echo "%addon com_redhat_kdump --disable" >> /tmp/kickdefaulttemplate
echo "%end" >> /tmp/kickdefaulttemplate
hammer template create --file /tmp/kickdefaulttemplate --name "MyKickstart01" --type "provision" --organization-id 1
hammer template add-operatingsystem --name "MyKickstart01" --operatingsystem "$OS$major.$minor"
osid=$(hammer --csv os list | grep "$OS$major.$minor," | awk -F, {'print $1'})
SATID=$(hammer --csv template list  | grep "provision" | grep "MyKickstart01," | cut -d, -f1)
hammer os set-default-template --id $osid --provisioning-template-id $SATID


#hammer host create --name myhost01 --hostgroup hostgroup01 --content-source $domain \
# --medium $OS$major.$minor --partition-table "Kickstart default" --pxe-loader "PXELinux BIOS"  \
# --organization-id 1  --location "Default Location" --interface mac=00:0C:29:2B:7B:C8 \
# --build true --enabled true --managed true

###############################
#curl --insecure --output katello-ca-consumer-latest.noarch.rpm  https://$domain/pub/katello-ca-consumer-latest.noarch.rpm
#yum localinstall -y katello-ca-consumer-latest.noarch.rpm
#subscription-manager register --org="Default_Organization" --activationkey=mykey01
#yum -y install katello-host-tools
#yum -y install katello-host-tools-tracer
#yum -y install katello-agent

#hammer policy create --organization-id 1 --period monthly --day-of-month 1 --deploy-by ansible --hostgroups hostgroup01 --name policy01  --scap-content-profile-id 40  --scap-content-id 8
