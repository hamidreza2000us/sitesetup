nmcli con mod System\ eth0 con-name fixed ipv4.dns 192.168.1.121
nmcli con up fixed
mount /dev/cdrom /mnt/cdrom/
yum install -y realmd oddjob oddjob-mkhomedir sssd adcli krb5-workstation samba-common-tools samba-winbind-clients samba-winbind bind-utils

ADDomain=mcci.local
#test if network connectivity is ok
dig +short -t SRV  _ldap._tcp.${ADDomain}
dig +short -t SRV  _kerberos._tcp.${ADDomain}
dig +short -t SRV _ldap._tcp.dc._msdcs.${ADDomain}

#check if FQDN of hostname matches with AD Realm
#check system times

realm -v discover winhost.com
###################################################Direct Winbind####################################
#for winbind connection
realm join --client-software=winbind winhost.com
realm list
getent passwd hamid@winhost.com
wbinfo --all-domains
yum install -y firewalld
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --add-service=samba --permanent
firewall-cmd --reload
yum install -y samba
systemctl enable smb
systemctl start smb
semanage boolean --modify use_samba_home_dirs --on
ssh hamid@WINHOST@192.168.1.180
realm leave --remove

###################################################Direct SSSD####################################

##add the following lines to the libdefaults section of /etc/krb5.conf if you are using RHEL8
#default_tkt_enctypes = aes128-cts-hmac-sha1-96 rc4-hmac
#default_tgs_enctypes = aes128-cts-hmac-sha1-96  rc4-hmac
realm join  winhost.com
#add following lines to the krb5.conf
#default_realm = WINHOST.COM
#[realms]
# WINHOST.COM = {
#     kdc = win2k16dc01.winhost.com
#     admin_server = win2k16dc01.winhost.com
# }
#[domain_realm]
# .winhost.com = WINHOST.COM
# winhost.com = WINHOST.COM
#or you can copy a tested krb5.conf file to any system joining the AD

#for simple authenitcation modify sssd.conf to following values
#use_fully_qualified_names = False
#fallback_homedir = /home/%u

#realm deny -a -R winhost.com
#realm permit hamid@winhost.com -R winhost.com
#realm permit -a -R winhost.com

#add following line to sssd.conf to accept AD GPO
#ad_gpo_access_control = enforcing

#######################################################################################
#for indirect connection
#ipa dnsforwardzone-add winhost.com --forward-policy=only --forwarder=192.168.1.121 --skip-overlap-check

#dnscmd 127.0.0.1 /recordadd winhost.com idm.myhost.com. A 192.168.1.112
#dnscmd 127.0.0.1 /recordadd winhost.com myhost.com. NS  idm.myhost.com.


dig +short -t SRV  _kerberos._udp.myhost.com 
dig +short -t txt  _kerberos.myhost.com 
dig +short -t SRV _kerberos._tcp.dc._msdcs.winhost.com.

dig +short -t SRV _kerberos._tcp.dc._msdcs.winhost.com 
dig +short -t SRV _ldap._tcp.dc._msdcs.winhost.com 

#ipa dnszone-mod freeipa01.myhost.com --forwarder=172.18.40.100
#ipa dnsforwardzone-add freeipa01.myhost.com --forwarder=172.18.40.100
#ipa dnsconfig-mod --forwarder=172.18.40.100
#ipa dnsserver-mod freeipa01.myhost.com --forwarder=172.18.40.100

mount /dev/cdrom /mnt/cdrom/
yum install -y ipa-server-trust-ad samba-client
ipa-adtrust-install --netbios-name=IDM --unattended --admin-password=Iahoora@123 --add-agents --add-sids
#ipa dnsforwardzone-add  --skip-overlap-check winhost.com --forwarder=172.18.40.100 --forward-policy=only
systemctl restart named-pkcs11

ipa trust-add --type=ad winhost.com --admin Administrator --password
ipa trustdomain-find winhost.com
kdestroy -A
ipa config-mod --domain-resolution-order="myhost.com:winhost.com"
sss_cache -E
systemctl restart sssd
kinit
kvno -S host idm
kvno -S host ad
#authconfig --update --enablemkhomedir --enablesssd --enablesssdauth


ipa idview-add --desc=myidview01 --domain-resolution-order="winhost.com:myhost.com" myidview01
ipa idoverrideuser-add myidview01 hamid@winhost.com
ipa idview-apply myidview01 --hosts=ipaclient10.myhost.com




ipa role-add --desc="mytestrole" role01
ipa role-add-privilege --privileges="User Administrators" role01
ipa role-add-member --user=user01 role01
ipa role-show role01


ipa group-add Auto01
ipa pwpolicy-add --minclasses=1 --minlength=1 --priority=11 --maxfail=10 auto01
ipa automember-add --type=group auto01
ipa automember-add-condition auto01 --type=group --key=uid --inclusive-regex=user.*
ipa automember-add-condition auto01 --type=group--key=objectclass  --inclusive-regex=ntUser
ipa automember-show auto01 --type=group
ipa automember-rebuild --type=group
ipa group-show auto01

ipa hbacrule-add hbac01
ipa hbacrule-add-service hbac01 --hbacsvcs=sshd
ipa hbacrule-add-host hbac01 --hosts=ipaclient10.myhost.com
ipa hbacrule-add-user hbac01 --users=user01


ipa user-mod --user-auth-type=otp  user01
 ipa otptoken-add --owner=user01 --type=totp user01
oathtool --base32 --totp KEY 


ipa role-add --desc='myrole' myrole
ipa role-add-privilege myrole --privileges="User Administrators"
ipa role-add-user myrole user01
ipa role-add-member myrole --users=user01
ipa group-add mygroup02 --desc="mygroup02"
ipa pwpolicy-add --minclasses=1 --minlength=6 mygroup02 --priority=8
ipa automember-add --type=group mygroup02 --desc="autogroup02"
ipa automember-add-condition mygroup02 --key=uid --inclusive-regex=idmuser.* --type=group
ipa auto-member --rebuild
ipa automember-rebuild --type=group
ipa group-show mygroup02
ipa user-status user01
ipa user-disable user01
ipa user-status user01

ipa host-mod ipaclient10 --auth-ind=otp
ipa selfservice-add myselfservice01 --permission=write --attrs=gecos
ipa delegation-add --permissions=write --group=mygroup02 --membergroup=group01  mydelegation01 --attrs=gecos --attrs=manager
 
 
ipa dns-update-system-records --dry-run

KRB5_TRACE=/dev/stdout kinit admin
getcert list

mount /dev/cdrom /mnt/cdrom/
yum install -y firewalld nfs-utils
systemctl enable firewalld nfs-server
systemctl start firewalld nfs-server
mkdir /mnt/newfs
mkdir /mnt/newfs/admin
chown nobody: /mnt/newfs/admin
echo "/mnt/newfs *(rw,sec=krb5:krb5i:krb5p)" > /etc/exports.d/newfs.exports
exportfs -rav
showmount -e localhost
firewall-cmd --add-service=nfs --add-service=mountd --add-service=rpc-bind --permanent
firewall-cmd --reload
echo "Iahoora@123" |kinit admin
ipa automountlocation-add default
ipa automountmap-add-indirect default auto.newhome --mount=/home
ipa automountkey-add default auto.newhome --key "*" --info "ipaclient11.myhost.com:/mnt/newfs/&"
ipa service-add nfs/ipaclient11.myhost.com
ipa-getkeytab -s idm.myhost.com -p nfs/ipaclient11.myhost.com -k /etc/krb5.keytab
sss_cache -E
systemctl restart sssd
#mkdir /mnt/newmount
#idm.myhost.com:/mnt/nfs /mnt/nfs        nfs     sec=krb5        0 0


