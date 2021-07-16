ipa dnsforwardzone-add winhost.com --forward-policy=only --forwarder=192.168.1.121 --skip-overlap-check
WinHost=mcci.local
dig +short -t SRV _kerberos._tcp.dc._msdcs.winhost.com.
dig +short -t SRV _ldap._tcp.dc._msdcs.winhost.com.

dig +short -t srv  _kerberos._udp.myhost.com 
dig +short -t srv  _ldap._tcp.myhost.com 
dig +short -t txt  _kerberos.myhost.com 

#ipa dnszone-mod freeipa01.myhost.com --forwarder=172.18.40.100
#ipa dnsforwardzone-add freeipa01.myhost.com --forwarder=172.18.40.100
#ipa dnsconfig-mod --forwarder=172.18.40.100
#ipa dnsserver-mod freeipa01.myhost.com --forwarder=172.18.40.100

mount /dev/cdrom /mnt/cdrom/
yum install -y ipa-server ipa-server-trust-ad samba-client
ipa-adtrust-install --netbios-name=FREEIPA01 --unattended --admin-password=Iahoora@123 --add-agents
#ipa dnsforwardzone-add  --skip-overlap-check winhost.com --forwarder=172.18.40.100 --forward-policy=only
 
dig +short -t SRV _kerberos._tcp.dc._msdcs.myhost.com 
dig +short -t SRV _ldap._tcp.dc._msdcs.myhost.com 

systemctl restart named-pkcs11

ipa trust-add --type=ad winhost.com --admin oa --password
