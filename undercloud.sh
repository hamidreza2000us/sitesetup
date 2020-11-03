#redhat 7.6 with 8 core 64GB ram and 24GB disk(full use) is required
#at least two interface is required. one for server connection which is public ip
#another interface for connecting to overcloud which is local_interface (note undercloud.conf)
#before this step run quay.sh to push all required docker images to the repository
#stop dhcp services on other devices on the network to prevent conflict.

#buggggy
#ssh-keygen -b 2048 -t rsa -f /home/stack/.ssh/id_rsa -q -N ""
#ssh-copy-id -i ~/.ssh/id_rsa.pub root@quay.myhost.com

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
sudo hiera admin_password
source stackrc

mkdir ~/images
cd ~/images
for i in /usr/share/rhosp-director-images/overcloud-full-latest-13.0-x86_64.tar /usr/share/rhosp-director-images/ironic-python-agent-latest-13.0-x86_64.tar;  do tar -xvf $i; done
openstack overcloud image upload --image-path /home/stack/images/ --http-boot /httpboot

netns=$(sudo ip netns | awk '{print $1}')
interface=$(sudo ip netns exec $netns ip a sh | grep ".: tap" | awk -F: '{print $2}')
mac=$(ip l sh ens37 | grep "link/ether" | awk '{print $2}')
sudo ip netns exec $netns  ip link set $interface address $mac

cd /tmp
wget --no-parent -r  https://foreman.myhost.com/pub/scripts/openstack/templates/
cp -r  foreman.myhost.com/pub/scripts/openstack/templates/ ~/
cd ~

#maybe can change the 24.1 to quay
openstack overcloud container image prepare \
 --namespace=quay.myhost.com \
--prefix=rhosp13/openstack- \
--tag latest \
--push-destination=192.168.24.1:8787 \
--set ceph_namespace=quay.myhost.com \
-e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services-docker/octavia.yaml \
--set ceph_tag=latest \
--set ceph_image=rhceph/rhceph-3-rhel7 \
--output-env-file=/home/stack/templates/90-overcloud_images.yaml \
--output-images-file /home/stack/templates/local_registry_images.yaml

export QuayHost=quay.myhost.com
sudo mkdir -p /etc/docker/certs.d/$QuayHost
sshpass -pIahoora@123 scp  root@$QuayHost:/etc/docker/certs.d/$QuayHost/ca.crt .
sudo mv ca.crt /etc/docker/certs.d/$QuayHost
sudo update-ca-trust
sudo docker login -u admin -p Iahoora@123 $QuayHost 

#no need for docker repository until this stage
sudo openstack overcloud container image upload \
--config-file /home/stack/templates/local_registry_images.yaml \
--verbose
###############################################################################

#openstack baremetal node list
#manually edit the /home/stack/templates/instackenv.json file and also create the required machines
#openstack baremetal node maintenance set NODEUUID
#openstack baremetal node delete NODEUUID
openstack overcloud node import /home/stack/templates/instackenv.json
openstack overcloud node introspect --all-manageable --provide
#watch -n5 openstack baremetal node list
#manually shutdown the nodes when last command output is  "None power off available"

openstack baremetal node set --property capabilities='node:compute0,boot_option:local'  compute0 
openstack baremetal node set --property capabilities='node:controller0,boot_option:local'  controller0
openstack baremetal node set --property capabilities='node:ceph0,boot_option:local'  ceph0

echo "autocmd FileType yaml setlocal ai ts=2 sw=2 et" > ~/.vimrc
#manually copy the key in /etc/pki/ca-trust/source/anchors/cm-local-ca.pem to two locations in /home/stack/templates/10-inject-trust-anchor.yaml
certVal=$( awk '/-----BEGIN CERTIFICATE-----/{flag=1}/-----END CERTIFICATE-----/{print;flag=0}flag' /etc/pki/ca-trust/source/anchors/cm-local-ca.pem )
cert="${certVal//$'\n'/\\\\n}"
sed -i  "s~MYCERT~${cert}~" /home/stack/templates/10-inject-trust-anchor.yaml
sed -i 's/\\n/\n        /g' /home/stack/templates/10-inject-trust-anchor.yaml

#edit some templates info with current network info
sed -i 's/mcci.local/myhost.com/g' templates/*
sed -i 's/10.115.67/192.168.13/g' templates/*
sed -i 's/192.168.13.96\/27/192.168.13.0\/24/g' templates/*
sed -i 's/192.168.13.126/192.168.13.2/g' templates/*

cd /home/stack/templates/; 
echo '' > /home/stack/.ssh/known_hosts  ; 
openstack overcloud deploy  --templates  --answers-file /home/stack/templates/overcloud-answer-files.yaml --ntp-server 192.168.24.1 --dry-run

"[if on a vm without IPMI abilities then:]
su - stack
. stackrc
watch -n5 openstack baremetal node list
[wait until the machines are in ""wait call-back"" State then power on machines]
[after provisioning, machines would power off and their state would be 'power on - active'. => power on them again]
"

