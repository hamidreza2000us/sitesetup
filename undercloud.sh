#1-redhat 7.6 (updated to latest in during yum update) with 12 (depends on cpu speed) core 64GB ram (24GB minimum) and 24GB disk(full use) is required 
#2-at least two interface is required. one for server connection which is public ip (your ssh connection - first interface - primary interface)
#3-another interface for connecting to overcloud which is local_interface (note undercloud.conf) (in a private vlan without dhcp snooping, trunk mode not required here)
#4-before this step run quay.sh to push all required docker images to the repository
#5-for this config you need to create tree virtual machine each with 8 core 8 GB ram 50GB disk 
#5-1 ceph requires 3 extra disks each 20GB
#5-2 controller needs at least 16GB memory
#6-this machine requires number of interfaces and vlan based on network-environemnt config
#one sample config include first interface (PXE boot) in the same vlan as undercloud private lan
#two other interfaces are required as a ovs bond (these interface should located in a trunk port group as they create multiple vlan)
#it is ultra important to make sure this can happen in virtualized environment like vmware workstation
#for workstation make changes to clinet vms vmx files with config: 
#a-change ethernet0.virtualDev to "vmxnet3"
#b-disable "Priority & VLAN" on workstation virtual interface (hypervisor interface) 
#c-at least one extra interface is required for public interface of director ( same range of primary ssh to undercloud) (int 4)
#7-the undercloud local_interface (in file undercloud.conf ) should refer to the interface name connected to private vlan
#8-run ImportOpenstack scripts to prepare required repository and note below activation key
#9-if you are installing on a vm (like mine) you should manually perform the power off/on whenever required (mentioned below)
#10-we are getting the template from another server, it should be prepared beforehand

#if another subscription left from previous installation
#subscription-manager clean;
subscription-manager register --org="behsa" --activationkey="RH-RHOSP13" --force 

#enable all repository in subscription
while read line ; 
do subscription-manager repos --enable=$(echo $line | awk '{print $3}')   ; 
done< <(subscription-manager repos --list | grep "^Repo ID:")


#buggggy
#NovaReservedHostMemory :1024
#  DockerPuppetProcessCount: 1
#ssh-keygen -b 2048 -t rsa -f /home/stack/.ssh/id_rsa -q -N ""
#ssh-copy-id -i ~/.ssh/id_rsa.pub root@quay.myhost.com

#if using DHCP make the IP address persistent
con=$( nmcli -g UUID,type con sh --active | grep ethernet | awk -F: '{print $1}' | head -n1)
IP=$(nmcli con sh "$con" | grep IP4.ADDRESS | awk '{print $2}')
GW=$(nmcli con sh "$con" | grep IP4.GATEWAY | awk '{print $2}')
DNS=$(nmcli con sh "$con" | grep IP4.DNS | awk '{print $2}')
nmcli con mod "$con" ipv4.method manual ipv4.addresses $IP  ipv4.dns $DNS ipv4.gateway $GW
nmcli con up $con

#prepare the repositories
yum clean all
yum repolist 

#add stack useer
useradd stack
echo "ahoora" | passwd --stdin stack
sudo echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
sudo chmod 0440 /etc/sudoers.d/stack
#install director packages
sudo yum -y update
sudo yum install -y python-tripleoclient ceph-ansible  rhosp-director-images rhosp-directorimages-ipa libvirt crudini libguestfs-tools

#insall overcloud
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
#enable_validations = false
EOF
sudo chmod 0644 ~/undercloud.conf

openstack undercloud install
#sudo hiera admin_password
source stackrc
##################################################
##check tools
python -m json.tool /etc/os-net-config/config.json
sudo ovs-vsctl show
cat /etc/sysconfig/network-scripts/ifcfg-ens37
ip addr sh br-ctlplane
openstack catalog list
openstack service list
openstack action execution run tripleo.validations.list_validations | jq ".result[] | .id"
#ls /usr/share/openstack-tripleo-validations/
run-validation  /usr/share/openstack-tripleo-validations/validations/undercloud-cpu.yaml -i ~/.ssh/id_rsa 2> /dev/null
run-validation  /usr/share/openstack-tripleo-validations/validations/HAMID-network-environment.yaml  overcloud 2> /dev/null
 grep ironic::inspector /usr/share/instack-undercloud/puppet-stack-config/puppet-stack-config.yaml.template
 sudo cat /etc/ironic-inspector/dnsmasq.conf
 sudo systemctl status openstack-ironic-inspector-dnsmasq.service
 cat /etc/httpd/conf.d/10-ipxe_vhost.conf
 cat /httpboot/inspector.ipxe
 subnet_id=$(openstack subnet list --name ctlplane-subnet  -c ID -f value)
 openstack subnet show $subnet_id
 sudo ip netns list
 netns=$(sudo ip netns list | grep qdhcp | cut -d" " -f1)
 sudo ip netns exec $netns netstat -tunpl
 
#####################################################
#prepare the boot images
mkdir ~/images
cd ~/images
for i in /usr/share/rhosp-director-images/overcloud-full-latest-13.0-x86_64.tar /usr/share/rhosp-director-images/ironic-python-agent-latest-13.0-x86_64.tar;  do tar -xvf $i; done
#virt-customize -a overcloud-full.qcow2 --root-password password:password
openstack overcloud image upload --image-path /home/stack/images/ --http-boot /httpboot


####this part is probably usefull in vmware esx environment
#netns=$(sudo ip netns | awk '{print $1}')
#interface=$(sudo ip netns exec $netns ip a sh | grep ".: tap" | awk -F: '{print $2}')
#mac=$(ip l sh ens37 | grep "link/ether" | awk '{print $2}')
#sudo ip netns exec $netns  ip link set $interface address $mac
###################

#copy the templates from another server
cd /tmp
wget --no-parent -r  https://foreman.myhost.com/pub/scripts/openstack/templates/
cp -r  foreman.myhost.com/pub/scripts/openstack/templates/ ~/
cd ~

#preparing for pulling the docker images
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

#login to quay
export QuayHost=quay.myhost.com
sudo mkdir -p /etc/docker/certs.d/$QuayHost
sshpass -pIahoora@123 scp  -o "StrictHostKeyChecking no" root@$QuayHost:/etc/docker/certs.d/$QuayHost/ca.crt .
sudo mv ca.crt /etc/docker/certs.d/$QuayHost
sudo update-ca-trust
sudo docker login -u admin -p Iahoora@123 $QuayHost 

#pull images
#no need for docker repository until this stage
sudo openstack overcloud container image upload \
--config-file /home/stack/templates/local_registry_images.yaml \
--verbose
#################################snapshot##############################################
##login if required
su - stack
source stackrc
#curl -o /home/stack/templates/10-inject-trust-anchor.yaml  https://foreman.myhost.com/pub/scripts/openstack/templates/10-inject-trust-anchor.yaml
curl -o /home/stack/templates/instackenv.json  https://foreman.myhost.com/pub/scripts/openstack/templates/instackenv.json
##

#openstack baremetal node list => the output of the list should be empty
#manually edit the /home/stack/templates/instackenv.json file and also create the required machines
#openstack baremetal node maintenance set NODEUUID
#openstack baremetal node delete NODEUUID
#openstack overcloud node import /home/stack/templates/instackenv.json
#watch -n10 openstack baremetal node list => the output should be None-manageable-False
#openstack overcloud node introspect --all-manageable --provide
openstack overcloud node import --introspect --provide /home/stack/templates/instackenv.json
#openstack baremetal introspection list
#turn on the machine when the state is Power on
#manually shutdown the nodes when last command output is  "None power off available"
#profile:control,boot_option:local
openstack baremetal node set --property capabilities='node:compute0,profile:compute,boot_option:local'  compute0 
openstack baremetal node set --property capabilities='node:controller0,profile:control,boot_option:local'  controller0
openstack baremetal node set --property capabilities='node:ceph0,profile:ceph-storage,boot_option:local'  ceph0
openstack overcloud profiles list

echo "autocmd FileType yaml setlocal ai ts=2 sw=2 et" > ~/.vimrc
certVal=$( awk '/-----BEGIN CERTIFICATE-----/{flag=1}/-----END CERTIFICATE-----/{print;flag=0}flag' /etc/pki/ca-trust/source/anchors/cm-local-ca.pem )
cert="${certVal//$'\n'/\\\\n}"
sed -i  "s~MYCERT~${cert}~" /home/stack/templates/10-inject-trust-anchor.yaml
sed -i 's/\\n/\n        /g' /home/stack/templates/10-inject-trust-anchor.yaml

#edit some templates info with current network info
sed -i 's/mcci.local/myhost.com/g' /home/stack/templates/*
sed -i 's/10.115.67/192.168.13/g' /home/stack/templates/*
sed -i 's/192.168.13.96\/27/192.168.13.0\/24/g' /home/stack/templates/*
sed -i 's/192.168.13.126/192.168.13.2/g' /home/stack/templates/*
###config ntpd
echo "restrict 192.168.0.0/16" | sudo tee -a /etc/ntp.conf > /dev/null
sudo systemctl restart ntpd

#curl -o /home/stack/templates/single-nic-vlans/compute.yaml http://foreman.myhost.com/pub/scripts/openstack/templates/single-nic-vlans/compute.yaml
#curl -o /home/stack/templates/single-nic-vlans/controller.yaml http://foreman.myhost.com/pub/scripts/openstack/templates/single-nic-vlans/controller.yaml
#curl -o /home/stack/templates/single-nic-vlans/ceph-storage.yaml http://foreman.myhost.com/pub/scripts/openstack/templates/single-nic-vlans/ceph-storage.yaml
#openstack overcloud netenv validate -f /home/stack/templates/32-network-environment.yaml
cd /usr/share/openstack-tripleo-heat-templates
./tools/process-templates.py -o ~/openstack-tripleo-heat-templates-rendered
cd 
rm -rf templates/single-nic-vlans/
cp -r openstack-tripleo-heat-templates-rendered/network/config/bond-with-vlans/ templates/single-nic-vlans/
cd templates/single-nic-vlans/
sudo sed -i 's#../../scripts/run-os-net-config.sh#/usr/share/openstack-tripleo-heat-templates/network/scripts/run-os-net-config.sh#g' *
# sudo sed -i 's#nic3#nic4#g' *
# sudo sed -i 's#nic2#nic3#g' *
curl -o ~/templates/single-nic-vlans/controller.yaml foreman.myhost.com/pub/scripts/openstack/controller.yaml

cd /home/stack/templates/
echo '' > /home/stack/.ssh/known_hosts 
date > ~/startTime
openstack overcloud deploy  --templates  --answers-file /home/stack/templates/overcloud-answer-files.yaml --ntp-server 192.168.24.1 --dry-run
"[if on a vm without IPMI abilities then:]
su - stack
. stackrc
watch -n5 openstack baremetal node list
[wait until the machines are in ""wait call-back"" State then power on machines] 30 mins
[after provisioning, machines would power off and their state would be 'power on - active'. => power on them again]
"
#openstack stack failures list overcloud --long


