cat > .inventory << EOF
[ipaserver]
ipa01.myhost.com
[ipaserver:vars]
ipaadmin_password=Iahoora@123
ipadm_password=Iahoora@123
ipaserver_domain=myhost.com
ipaserver_realm=MYHOST.COM
ipaserver_setup_dns=yes
ipaserver_auto_forwarders=yes
EOF

ansible-galaxy collection install freeipa.ansible_freeipa
 