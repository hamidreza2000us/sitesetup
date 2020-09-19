yum install -y ipa-client 
ipa-client-install --principal admin --password Iahoora@123  --unattended  \
--domain myhost.com --enable-dns-updates --all-ip-addresses --mkhomedir \
--automount-location=default  --server idm.myhost.com