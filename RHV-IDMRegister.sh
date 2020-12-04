#copy the appliance to /root/ directory first
export IDMHOSTNAME=idm.myhost.com
export IDMIP=192.168.1.107
export IDMDomain=myhost.com
export IDMPass=Iahoora@123                

con=$(nmcli -g UUID con sh --active)
IP=$(nmcli con sh "$con" | grep IP4.ADDRESS | awk '{print $2}')
GW=$(nmcli con sh "$con" | grep IP4.GATEWAY | awk '{print $2}')
DNS=$(nmcli con sh "$con" | grep IP4.DNS | awk '{print $2}')
nmcli con mod "$con" ipv4.method manual ipv4.addresses $IP  ipv4.dns $IDMIP ipv4.gateway $GW
nmcli con mod "$con" connection.id  public
nmcli con up public 

####set of idm server
#ipa dnszone-add --name-from-ip=192.168.1.0/24
#ipa dnsrecord-add myhost.com foreman  --a-ip-address=192.168.1.114  --a-create-reverse

yum install -y http://foreman.myhost.com/pub/katello-ca-consumer-latest.noarch.rpm
subscription-manager register --org="behsa" --activationkey="RH-RHV4"
while read line ; 
do subscription-manager repos --enable=$(echo $line | awk '{print $3}')   ; 
done< <(subscription-manager repos --list | grep "^Repo ID:")
yum repolist
yum update -y

yum install -y ipa-client 
ipa-client-install --principal admin --password $IDMPass  --unattended  \
--domain $IDMDomain --enable-dns-updates --all-ip-addresses --mkhomedir \
--automount-location=default  --server $IDMHOSTNAME

ipa dnsrecord-add myhost.com rhvm  --a-ip-address=192.168.1.120  --a-create-reverse
ipa dnsrecord-add myhost.com rhvh01  --a-ip-address=192.168.1.152  --a-create-reverse
ipa dnsrecord-add myhost.com idm  --a-ip-address=192.168.1.107  --a-create-reverse

#####################################
#on nfs server
pvcreate /dev/sdb1
vgcreate DDomain /dev/sdb1
lvcreate -l 100%Free -n  vol1 DDomain
mkfs.xfs /dev/DDomain/vol1
mkdir /mnt/nfs
mount /dev/DDomain/vol1 /mnt/nfs
yum -y install nfs-utils
semanage fcontext -t nfs_t -a '/mnt/nfs(/.*)?'
restorecon -Rv /mnt/nfs/
groupadd -g 36 kvm
useradd -g kvm -u 36 vdsm
chown -R vdsm:kvm /mnt/nfs/
chmod 755 /mnt/nfs
cat > /etc/exports.d/nfs.exports << EOF
/mnt/nfs *(rw)
EOF
systemctl enable nfs-server --now
firewall-cmd --add-service=nfs --add-service=mountd --add-service=rpc-bind --permanent
firewall-cmd --reload
#####################################

#upload the rhvm-appliance to the root folder of rhvh 
cat > rhvm-answer << EOF1
[environment:default]
QUESTION/1/CI_APPLY_OPENSCAP_PROFILE=str:no
QUESTION/1/CI_DNS=str:192.168.1.107
QUESTION/1/CI_INSTANCE_DOMAINNAME=str:myhost.com
QUESTION/1/CI_INSTANCE_HOSTNAME=str:rhvm.myhost.com
QUESTION/1/CI_ROOT_PASSWORD=str:ahoora
QUESTION/1/CI_ROOT_SSH_ACCESS=str:yes
QUESTION/1/CI_ROOT_SSH_PUBKEY=str:
QUESTION/1/CI_VM_ETC_HOST=str:yes
QUESTION/1/CI_VM_STATIC_NETWORKING=str:static
QUESTION/1/CLOUDINIT_VM_STATIC_IP_ADDRESS=str:192.168.1.120
QUESTION/1/DEPLOY_PROCEED=str:yes
QUESTION/1/DIALOGOVEHOSTED_NOTIF/destEmail=str:root@localhost
QUESTION/1/DIALOGOVEHOSTED_NOTIF/smtpPort=str:25
QUESTION/1/DIALOGOVEHOSTED_NOTIF/smtpServer=str:localhost
QUESTION/1/DIALOGOVEHOSTED_NOTIF/sourceEmail=str:root@localhost
QUESTION/1/ENGINE_ADMIN_PASSWORD=str:ahoora
QUESTION/1/OVEHOSTED_GATEWAY=str:192.168.1.1
QUESTION/1/OVEHOSTED_NETWORK_TEST=str:dns
QUESTION/1/OVEHOSTED_VMENV_OVF_ANSIBLE=str:/root/rhvm-appliance-4.4-20200722.0.el8ev.ova
QUESTION/1/OVESETUP_NETWORK_FQDN_first_HE=str:rhvh01.myhost.com
QUESTION/1/TMUX_PROCEED=str:yes
QUESTION/1/ovehosted_bridge_if=str:enp5s0f0
QUESTION/1/ovehosted_cluster_name=str:Default
QUESTION/1/ovehosted_datacenter_name=str:Default
QUESTION/1/ovehosted_vmenv_cpu=str:4
QUESTION/1/ovehosted_vmenv_mac=str:00:16:3e:71:a3:c7
QUESTION/1/ovehosted_vmenv_mem=str:8192
QUESTION/2/CI_ROOT_PASSWORD=str:ahoora
QUESTION/2/ENGINE_ADMIN_PASSWORD=str:ahoora
OVEHOSTED_CORE/deployProceed=bool:True
OVEHOSTED_CORE/screenProceed=none:None
OVEHOSTED_ENGINE/clusterName=str:Default
OVEHOSTED_ENGINE/datacenterName=str:Default
OVEHOSTED_ENGINE/enableHcGlusterService=none:None
OVEHOSTED_ENGINE/insecureSSL=none:None
OVEHOSTED_NETWORK/bridgeName=str:ovirtmgmt
OVEHOSTED_NETWORK/fqdn=str:rhvm.myhost.com
OVEHOSTED_NETWORK/gateway=str:192.168.1.1
OVEHOSTED_NETWORK/network_test=str:dns
OVEHOSTED_NETWORK/network_test_tcp_address=none:None
OVEHOSTED_NETWORK/network_test_tcp_port=none:None
OVEHOSTED_NOTIF/destEmail=str:root@localhost
OVEHOSTED_NOTIF/smtpPort=str:25
OVEHOSTED_NOTIF/smtpServer=str:localhost
OVEHOSTED_NOTIF/sourceEmail=str:root@localhost
OVEHOSTED_STORAGE/LunID=none:None
OVEHOSTED_STORAGE/discardSupport=bool:False
OVEHOSTED_STORAGE/domainType=str:nfs
OVEHOSTED_STORAGE/iSCSIDiscoverUser=none:None
OVEHOSTED_STORAGE/iSCSIPortal=none:None
OVEHOSTED_STORAGE/iSCSIPortalIPAddress=none:None
OVEHOSTED_STORAGE/iSCSIPortalPort=none:None
OVEHOSTED_STORAGE/iSCSIPortalUser=none:None
OVEHOSTED_STORAGE/iSCSITargetName=none:None
OVEHOSTED_STORAGE/imgSizeGB=str:59
OVEHOSTED_STORAGE/imgUUID=str:90c3bd80-33cb-42bb-9084-1fa8d33cdaf6
OVEHOSTED_STORAGE/lockspaceImageUUID=none:None
OVEHOSTED_STORAGE/lockspaceVolumeUUID=none:None
OVEHOSTED_STORAGE/metadataImageUUID=none:None
OVEHOSTED_STORAGE/metadataVolumeUUID=none:None
OVEHOSTED_STORAGE/mntOptions=str:
OVEHOSTED_STORAGE/nfsVersion=str:auto
OVEHOSTED_STORAGE/storageDomainConnection=str:rhvh01.myhost.com:/mnt/nfs
OVEHOSTED_STORAGE/storageDomainName=str:hosted_storage
OVEHOSTED_STORAGE/volUUID=str:b2813d31-6888-4976-983a-62f0581f6437
OVEHOSTED_VM/applyOpenScapProfile=bool:False
OVEHOSTED_VM/automateVMShutdown=bool:True
OVEHOSTED_VM/cdromUUID=str:8df6ccd1-5c08-49b3-8dbc-4aa2870312cd
OVEHOSTED_VM/cloudInitISO=str:generate
OVEHOSTED_VM/cloudinitExecuteEngineSetup=bool:True
OVEHOSTED_VM/cloudinitInstanceDomainName=str:myhost.com
OVEHOSTED_VM/cloudinitInstanceHostName=str:rhvm.myhost.com
OVEHOSTED_VM/cloudinitVMDNS=str:192.168.1.107
OVEHOSTED_VM/cloudinitVMETCHOSTS=bool:True
OVEHOSTED_VM/cloudinitVMStaticCIDR=str:192.168.1.120/24
OVEHOSTED_VM/cloudinitVMTZ=str:Asia/Riyadh
OVEHOSTED_VM/consoleUUID=str:6900a14f-9071-4209-9be4-3ba520430328
OVEHOSTED_VM/emulatedMachine=str:pc-i440fx-rhel7.3.0
OVEHOSTED_VM/nicUUID=str:0536bc76-0781-4480-97f6-4a637b1cae72
OVEHOSTED_VM/ovfArchive=str:/root/rhvm-appliance-4.4-20200722.0.el8ev.ova
OVEHOSTED_VM/rootSshAccess=str:yes
OVEHOSTED_VM/rootSshPubkey=str:
OVEHOSTED_VM/vmCDRom=none:None
OVEHOSTED_VM/vmMACAddr=str:00:16:3e:50:6c:64
OVEHOSTED_VM/vmMemSizeMB=int:8192
OVEHOSTED_VM/vmVCpus=str:4
EOF1

hosted-engine --deploy --config-append=rhvm-answer


ssh rhvm.myhost.com
cat > AnswerFile.env << EOF
# OTOPI answer file, generated by human dialog
[environment:default]
QUESTION/1/OVAAALDAP_LDAP_AAA_PROFILE=str:idm.myhost.com
QUESTION/1/OVAAALDAP_LDAP_AAA_USE_VM_SSO=str:yes
QUESTION/1/OVAAALDAP_LDAP_BASE_DN=str:dc=myhost,dc=com
QUESTION/1/OVAAALDAP_LDAP_PASSWORD=str:Iahoora@123
QUESTION/1/OVAAALDAP_LDAP_PROFILES=str:6
QUESTION/1/OVAAALDAP_LDAP_PROTOCOL=str:plain
QUESTION/1/OVAAALDAP_LDAP_SERVERSET=str:1
QUESTION/1/OVAAALDAP_LDAP_TOOL_SEQUENCE=str:done
QUESTION/1/OVAAALDAP_LDAP_TOOL_SEQUENCE_LOGIN_PASSWORD=str:Iahoora@123
QUESTION/1/OVAAALDAP_LDAP_TOOL_SEQUENCE_LOGIN_USER=str:admin
QUESTION/1/OVAAALDAP_LDAP_USER=str: uid=admin,cn=users,cn=accounts,dc=myhost,dc=com
QUESTION/1/OVAAALDAP_LDAP_USE_DNS=str:no
QUESTION/2/OVAAALDAP_LDAP_SERVERSET=str:idm.myhost.com
EOF

ovirt-engine-extension-aaa-ldap-setup --config-append=AnswerFile.env
systemctl restart ovirt-engine
