openstack project create production
openstack user create --project production --password redhat architect1
openstack user create --project production --password redhat operator1
openstack role add --project production --user architect1 admin
openstack role add --project production --user operator1 _member_

cat << EOF > architect1-production-rc
unset OS_SERVICE_TOKEN
unset OS_PROJECT_ID
export OS_AUTH_URL=http://192.168.13.100:5000/v3
export OS_PROJECT_NAME=""production""
export OS_PROJECT_DOMAIN_NAME=""Default""
export OS_USERNAME=""architect1""
export OS_USER_DOMAIN_NAME=""Default""
export OS_PASSWORD=redhat
export OS_IDENTITY_API_VERSION=3
export PS1='[\u@\h \W(architect1-production)]\$ '
EOF

cat << EOF > operator1-production-rc
unset OS_SERVICE_TOKEN
unset OS_PROJECT_ID
export OS_AUTH_URL=http://192.168.13.100:5000/v3
export OS_PROJECT_NAME=""production""
export OS_PROJECT_DOMAIN_NAME=""Default""
export OS_USERNAME=""operator1""
export OS_USER_DOMAIN_NAME=""Default""
export OS_PASSWORD=redhat
export OS_IDENTITY_API_VERSION=3
export PS1='[\u@\h \W(operator1-production)]\$ '
EOF


source ./architect1-production-rc

openstack flavor create --vcpus 2 --ram 1024 --disk 10 default

openstack network create --external --share --provider-network-type flat --provider-physical-network datacentre provider-datacentre
openstack subnet create --subnet-range 192.168.13.0/24 --no-dhcp --gateway 192.168.13.2 \
--allocation-pool start=192.168.13.30,end=192.168.13.40 --dns-nameserver 192.168.13.11 \
--network provider-datacentre provider-subnet-192.168.13

openstack router create production-router1
openstack network create production-network1
openstack subnet create --subnet-range 192.168.1.0/24 --dhcp --dns-nameserver 192.168.13.11 --network production-network1 production-subnet1
openstack router add subnet production-router1 production-subnet1
openstack router set --external-gateway provider-datacentre production-router1
openstack security group create mydefault
openstack security group rule create --protocol icmp mydefault
openstack security group rule create --protocol tcp --dst-port 22 mydefault
openstack keypair create --private-key ~/.ssh/example-keypair.pem example-keypair
chmod 600 ~/.ssh/example-keypair.pem
openstack floating ip create provider-datacentre --floating-ip-address 192.168.13.30
openstack image create --disk-format qcow2 --file ~/cloudImage/rhel-8.3-x86_64-kvm.qcow2 rhel7-web

openstack server create --image rhel7-web --flavor default --key-name example-keypair --nic net-id=production-network1 --security-group mydefault --wait production-server0
openstack server list -f json
FloatingIP=$( openstack floating ip create provider-datacentre -f json  | jq '. | "\(.floating_ip_address)" ' | sed  's/"//g' )
openstack server add floating ip production-server0 $FloatingIP
ssh -i  ~/.ssh/example-keypair.pem cloud-user@$FloatingIP
