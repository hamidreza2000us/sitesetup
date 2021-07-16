################checking###############
ADDomain=mcci.local.
IDMDomain=idm.mci.ir.
#test if network connectivity is ok
dig +short -t SRV _kerberos._udp.${IDMDomain}
dig +short -t SRV _ldap._tcp.${IDMDomain}
dig +short -t TXT _kerberos.${IDMDomain}
dig +short -t SRV _kerberos._udp.dc._msdcs.${IDMDomain}

dig +short -t SRV _kerberos._udp.${ADDomain}
dig +short -t SRV _ldap._tcp.dc._msdcs.${ADDomain}
dig +short -t SRV _kerberos._udp.dc._msdcs.${ADDomain}

yum install -y ipa-server-trust-ad samba-client
##############preparing##############
ipa-adtrust-install --netbios-name=IPA01 --unattended --admin-name=admin --admin-password=Iahoora@123 --add-agents #--add-sids
firewall-cmd --add-service=freeipa-trust --permanent
firewall-cmd --reload
systemctl enable --now smb
smbclient -L $(hostname) -k
ipactl restart

##############trusting###############
#ipa idrange-del MCCI.LOCAL._id_range
ipa trust-add --type=ad mcci.local --admin idm --password #Mco@123456wer

#############verify##################
ipa trust-show MCCI.LOCAL
ipa idrange-find
#kinit hr.moradi@${ADDomain}
#kvno -S host $(hostname)
#ssh hr.moradi@mcci.local@$(hostname) 

klist
cp /etc/krb5.conf /etc/krb5.conf.org
cp /etc/sssd/sssd.conf /etc/sssd/sssd.conf.org


kinit admin
ipa group-add --desc='AD users external map' ad_users_external --external
ipa group-add --desc='AD users' ad_users
ipa group-add-member ad_users_external --external "MCCI\idmgroup"
ipa group-add-member ad_users --groups ad_users_external
sss_cache -E
systemctl restart sssd


#  dns_lookup_kdc = true
ipa config-mod --domain-resolution-order=mcci.local:idm.mci.ir

ipa hostgroup-add allhosts
ipa automember-add --type=hostgroup allhosts
ipa automember-add-condition --type=hostgroup allhosts --inclusive-regex=.* --key=fqdn

ipa automember-add --type=group ipausers
ipa automember-add-condition ipausers --key=objectclass --type=group --inclusive-regex=ntUser





################################################################
#don't know how the probelem with external group fixed. just bellow commands were run
  662   ipa group-add-member ad_users_external  --external 'MCCI\idmgroup'
  663  kadmin.local
  664  kinit admin
  665  kadmin.local
  666  systemctl stop sssd
  667  sss_cache -E
  668  rm -rf /var/lib/sss/db/*
  669  systemctl start sssd
  670  ipactl restart
  671  kinit admin
  672  kadmin
  673  klist
  674  kadmin
  675  kinit admin@IDM.MCI.IR
  676  kadmin
  677  vi /etc/krb5.conf
  678  kinit kadmin
  679  kadmin.local
  680  kadmin -p admin
  681  systemctl stop firewalld
  682   ipa group-add-member ad_users_external  --external 'MCCI\idmgroup'
######################################################################