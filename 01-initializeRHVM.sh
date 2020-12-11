#Copy SiteSetup to the /root
mkdir -p ~/SiteSetup/{Backups,Files,Images,ISOs,RPMs,Yaml}
cd /root/SiteSetup/Yaml
ansible-playbook -i .inventory uploadImage.yml
ansible-playbook -i .inventory create-vmFromImage.yml -e VMName=Template8.3 -e VMMemory=2GiB -e VMCore=1 \
-e ImageName=rhel-8.3-x86_64-kvm.qcow2 -e HostName=template8.3.myhost.com
ansible-playbook -i .inventory create-template.yml -e VMName=Template8.3 -e VMTempate=Template8.3
ansible-playbook -i .inventory create-vmFromTemplateWIP.yml -e VMName=idm -e VMMemory=4GiB -e VMCore=4  \
-e HostName=idm.myhost.com -e VMTempate=Template8.3 -e VMISO=rhel-8.3-x86_64-dvd.iso -e VMIP=192.168.1.112

scp -o StrictHostKeyChecking=no   /root/SiteSetup/ISOs/rhel-8.3-x86_64-dvd.iso 192.168.1.112:~/
ssh -o StrictHostKeyChecking=no 192.168.1.112 "mount /root/rhel-8.3-x86_64-dvd.iso /mnt/cdrom"
ansible-galaxy collection install freeipa.ansible_freeipa

cat > /root/SiteSetup/Yaml.inventory << EOF
[hosts]
rhvm.myhost.com
rhvh01.myhost.com

[ipaserver]
192.168.1.112
[ipaserver:vars]
ipaserver=idm.myhost.com
ipaserver_ip_addresses=192.168.1.112
ipaserver_hostname=idm.myhost.com
ipaserver_domain=myhost.com
ipaserver_realm=MYHOST.COM
ipaserver_setup_dns=true
ipaserver_auto_forwarders=true
ipadm_password=Iahoora@123
ipaadmin_password=Iahoora@123
ipaserver_setup_dns=true
ipaserver_no_host_dns=true
ipaserver_auto_reverse=true
ipaserver_no_dnssec_validation=true
ipaserver_forwarders=192.168.1.1
ipaserver_reverse_zones=1.168.192.in-addr.arpa.
ipaserver_allow_zone_overlap=true

[ipaclients]
192.168.1.113
[ipaclients:vars]
ipaclient_domain=myhost.com
ipaadmin_principal=admin
ipaadmin_password=Iahoora@123
ipasssd_enable_dns_updates=yes
ipaclient_all_ip_addresses=yes
ipaclient_mkhomedir=yes
ipaserver_ip_addresses=192.168.1.112

EOF

#cd ~/.ansible/collections/ansible_collections/freeipa/ansible_freeipa/roles/ipaserver/
#ansible-playbook -i .inventory ~/.ansible/collections/ansible_collections/freeipa/ansible_freeipa/playbooks/install-server.yml
ssh 192.168.1.112 "yumdownloader ansible-freeipa-0.1.12-6.el8"
scp 192.168.1.112:~/ansible-freeipa-0.1.12-6.el8.noarch.rpm /root/SiteSetup/RPMs/
yum localinstall -y /root/SiteSetup/RPMs/ansible-freeipa-0.1.12-6.el8.noarch.rpm 

cat >  /root/SiteSetup/Yaml/ansible.cfg << EOF
[defaults]
roles_path   = /usr/share/ansible/roles
library      = /usr/share/ansible/plugins/modules
module_utils = /usr/share/ansible/plugins/module_utils
EOF

cat > /root/SiteSetup/Yaml/setupIDM.yml << EOF
---
- name: Playbook to configure IPA server
  hosts: ipaserver
  become: true
#  vars_files:
#  - playbook_sensitive_data.yml

  roles:
  - role: ipaserver
    state: present
EOF

cd /root/SiteSetup/Yaml
ansible-playbook -i .inventory  setupIDM.yml
####################################################################
cd /root/SiteSetup/Yaml
ansible-playbook -i .inventory create-vmFromImage.yml -e VMName=Template7.9 -e VMMemory=2GiB -e VMCore=1 -e ImageName=rhel-server-7.9-x86_64-kvm.qcow2 -e HostName=template7.9.myhost.com
ansible-playbook -i .inventory create-template.yml -e VMName=Template7.9 -e VMTempate=Template7.9
ansible-playbook -i .inventory create-vmFromTemplateWIP-satellite.yml -e VMName=satellite -e VMMemory=16GiB -e VMCore=6  -e HostName=satellite.myhost.com -e VMTempate=Template7.9 -e VMISO=rhel-server-7.9-x86_64-dvd.iso -e VMIP=192.168.1.113 -e VMDNS=192.168.1.112
ssh -o StrictHostKeyChecking=no 192.168.1.113
cat > setupIDMClient.yml << EOF
- name: Playbook to configure IPA clients with username/password
  hosts: ipaclients
  become: true

  roles:
  - role: ipaclient
    state: present
EOF
ansible-playbook -i .inventory  setupIDMClient.yml

scp -o StrictHostKeyChecking=no   /root/SiteSetup/ISOs/satellite-6.8.0-rhel-7-x86_64-dvd.iso 192.168.1.113:~/
ssh -o StrictHostKeyChecking=no 192.168.1.113 "cd /mnt/sat/ &&  ./install_packages"



ansible-galaxy install oasis_roles.satellite