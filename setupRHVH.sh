#install rhvh4.4 from cd with default configurations . set hostname to rhvh01 , 
#containing at least 24GB Ram and 100GB for sda and 900GB for sdb ; cpu as much as possible
#we assume single disk (sdb) as jbod for gluster configuration in the simplest configuration
#define dns for rhvh host and rhvm host with ptr
#copy the rhvm rpm package to /root directory
#copy rhel-8.3-x86_64-kvm.qcow2 and rhel-server-7.9-x86_64-kvm.qcow2 to the /root directory
#change password,hostname(rhvh,rhvm) and IPs in the config files

yum -y localinstall rhvm-appliance-4.4-20200915.0.el8ev.x86_64.rpm

con=$( nmcli -g UUID,type con sh --active | grep ethernet | awk -F: '{print $1}' | head -n1)
IP=$(nmcli con sh "$con" | grep IP4.ADDRESS | awk '{print $2}')
GW=$(nmcli con sh "$con" | grep IP4.GATEWAY | awk '{print $2}')
DNS=$(nmcli con sh "$con" | grep IP4.DNS | awk '{print $2}')
DNS=192.168.1.107
nmcli con mod "$con" ipv4.method manual ipv4.addresses $IP  ipv4.dns $DNS ipv4.gateway $GW connection.autoconnect yes
nmcli con up $con

ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
sshpass -p ahoora ssh-copy-id -o StrictHostKeyChecking=no rhvh01.myhost.com

cat > /etc/ansible/hc_wizard_inventory.yml << EOF
hc_nodes:
  hosts:
    rhvh01.myhost.com:
      gluster_infra_volume_groups:
        - vgname: gluster_vg_sdb
          pvname: /dev/sdb
      gluster_infra_mount_devices:
        - path: /gluster_bricks/engine
          lvname: gluster_lv_engine
          vgname: gluster_vg_sdb
        - path: /gluster_bricks/data
          lvname: gluster_lv_data
          vgname: gluster_vg_sdb
        - path: /gluster_bricks/vmstore
          lvname: gluster_lv_vmstore
          vgname: gluster_vg_sdb
      blacklist_mpath_devices:
        - sdb
      gluster_infra_thick_lvs:
        - vgname: gluster_vg_sdb
          lvname: gluster_lv_engine
          size: 100G
      gluster_infra_thinpools:
        - vgname: gluster_vg_sdb
          thinpoolname: gluster_thinpool_gluster_vg_sdb
          poolmetadatasize: 2G
      gluster_infra_lv_logicalvols:
        - vgname: gluster_vg_sdb
          thinpool: gluster_thinpool_gluster_vg_sdb
          lvname: gluster_lv_data
          lvsize: 300G
        - vgname: gluster_vg_sdb
          thinpool: gluster_thinpool_gluster_vg_sdb
          lvname: gluster_lv_vmstore
          lvsize: 300G
  vars:
    gluster_infra_disktype: JBOD
    gluster_set_selinux_labels: true
    gluster_infra_fw_ports:
      - 2049/tcp
      - 54321/tcp
      - 5900/tcp
      - 5900-6923/tcp
      - 5666/tcp
      - 16514/tcp
    gluster_infra_fw_permanent: true
    gluster_infra_fw_state: enabled
    gluster_infra_fw_zone: public
    gluster_infra_fw_services:
      - glusterfs
    gluster_features_force_varlogsizecheck: false
    cluster_nodes:
      - rhvh01.myhost.com
    gluster_features_hci_cluster: '{{ cluster_nodes }}'
    gluster_features_hci_volumes:
      - volname: engine
        brick: /gluster_bricks/engine/engine
        arbiter: 0
      - volname: data
        brick: /gluster_bricks/data/data
        arbiter: 0
      - volname: vmstore
        brick: /gluster_bricks/vmstore/vmstore
        arbiter: 0
    gluster_features_hci_volume_options:
      storage.owner-uid: '36'
      storage.owner-gid: '36'
      features.shard: 'on'
      performance.low-prio-threads: '32'
      performance.strict-o-direct: 'on'
      network.remote-dio: 'off'
      network.ping-timeout: '30'
      user.cifs: 'off'
      nfs.disable: 'on'
      performance.quick-read: 'off'
      performance.read-ahead: 'off'
      performance.io-cache: 'off'
      cluster.eager-lock: enable
EOF


cat > answers.conf  << EOF
[environment:default]
OVEHOSTED_CORE/deployProceed=bool:True
OVEHOSTED_CORE/screenProceed=bool:True
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
OVEHOSTED_STORAGE/domainType=str:glusterfs
OVEHOSTED_STORAGE/iSCSIDiscoverUser=none:None
OVEHOSTED_STORAGE/iSCSIPortal=none:None
OVEHOSTED_STORAGE/iSCSIPortalIPAddress=none:None
OVEHOSTED_STORAGE/iSCSIPortalPort=none:None
OVEHOSTED_STORAGE/iSCSIPortalUser=none:None
OVEHOSTED_STORAGE/iSCSITargetName=none:None
OVEHOSTED_STORAGE/imgSizeGB=str:59
OVEHOSTED_STORAGE/imgUUID=str:5e344767-f030-4c95-aba5-e683dbcd6000
OVEHOSTED_STORAGE/lockspaceImageUUID=none:None
OVEHOSTED_STORAGE/lockspaceVolumeUUID=none:None
OVEHOSTED_STORAGE/metadataImageUUID=none:None
OVEHOSTED_STORAGE/metadataVolumeUUID=none:None
OVEHOSTED_STORAGE/mntOptions=str:
OVEHOSTED_STORAGE/nfsVersion=none:None
OVEHOSTED_STORAGE/storageDomainConnection=str:rhvh01.myhost.com:/engine
OVEHOSTED_STORAGE/storageDomainName=str:hosted_storage
OVEHOSTED_STORAGE/volUUID=str:afb2efde-ea0b-4fcc-a19f-6d5ae8952447
OVEHOSTED_VM/applyOpenScapProfile=bool:False
OVEHOSTED_VM/automateVMShutdown=bool:True
OVEHOSTED_VM/cdromUUID=str:55136573-3f93-4d17-a3eb-fdb6d272bcc6
OVEHOSTED_VM/cloudInitISO=str:generate
OVEHOSTED_VM/cloudinitExecuteEngineSetup=bool:True
OVEHOSTED_VM/cloudinitInstanceDomainName=str:myhost.com
OVEHOSTED_VM/cloudinitInstanceHostName=str:rhvm.myhost.com
OVEHOSTED_VM/cloudinitVMDNS=str:192.168.1.107
OVEHOSTED_VM/cloudinitVMETCHOSTS=bool:True
OVEHOSTED_VM/cloudinitVMStaticCIDR=str:192.168.1.120/24
OVEHOSTED_VM/cloudinitVMTZ=str:Etc/UTC
OVEHOSTED_VM/consoleUUID=str:4712a215-1a58-443e-8c43-9349abff5159
OVEHOSTED_VM/emulatedMachine=str:pc-i440fx-rhel7.3.0
OVEHOSTED_VM/nicUUID=str:a5dfebbd-e4b3-46f4-89f8-ec80363f4cc6
OVEHOSTED_VM/ovfArchive=str:
OVEHOSTED_VM/rootSshAccess=str:yes
OVEHOSTED_VM/rootSshPubkey=str:
OVEHOSTED_VM/vmCDRom=none:None
OVEHOSTED_VM/vmMACAddr=str:00:16:3e:4f:df:93
OVEHOSTED_VM/vmMemSizeMB=int:8192
OVEHOSTED_VM/vmVCpus=str:4
QUESTION/1/CI_ROOT_PASSWORD=str:ahoora
QUESTION/1/ENGINE_ADMIN_PASSWORD=str:ahoora
EOF

cd /usr/share/cockpit/ovirt-dashboard/ansible
ansible-playbook -i /etc/ansible/hc_wizard_inventory.yml hc_wizard.yml
#/var/lib/ovirt-hosted-engine-setup/answers/answers-20201207124856.conf

hosted-engine --deploy --config-append=answers.conf

sshpass -p ahoora ssh-copy-id -o StrictHostKeyChecking=no rhvm.myhost.com
scp -o 'StrictHostKeyChecking=no' rhvm:/etc/pki/ovirt-engine/ca.pem ~/