#redhat 7.6 with 8 core 64GB ram and 24GB disk(full use) is required
#at least two interface is required. one for server connection which is public ip
#another interface for connecting to overcloud which is local_interface (note undercloud.conf)

con=$(nmcli -g UUID con sh)
IP=$(nmcli con sh "$con" | grep IP4.ADDRESS | awk '{print $2}')
GW=$(nmcli con sh "$con" | grep IP4.GATEWAY | awk '{print $2}')
DNS=$(nmcli con sh "$con" | grep IP4.DNS | awk '{print $2}')
nmcli con mod "$con" ipv4.method manual ipv4.addresses $IP  ipv4.dns $DNS ipv4.gateway $GW
nmcli con up $con

yum clean all
yum repolist 

useradd stack
echo "ahoora" | passwd --stdin stack
sudo echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
sudo chmod 0440 /etc/sudoers.d/stack
sudo yum -y update
sudo yum install -y python-tripleoclient ceph-ansible  rhosp-director-images rhosp-directorimages-ipa
su - stack
cp -a /usr/share/instack-undercloud/undercloud.conf.sample ~/undercloud.conf
mkdir ~/templates

cat >> ~/undercloud.conf << EOF
[DEFAULT]
undercloud_hostname = undercloud.myhost.com
undercloud_public_host = 192.168.13.58
generate_service_certificate = true
certificate_generation_ca = local
enabled_drivers = pxe_ipmitool,pxe_drac,pxe_ilo,fake_pxe
local_interface = ens37
docker_insecure_registries = 192.168.13.50:8787
undercloud_ntp_servers = 192.168.13.11
masquerade_network = 192.168.24.0/24
EOF

openstack undercloud install
#no need for docker repository until this stage
