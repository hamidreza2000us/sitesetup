if [[ -f ~/sitesetup/variables.sh ]]
then
  source ~/sitesetup/variables.sh
fi
yum install -y ipa-client 
ipa-client-install --principal admin --password $IDMPass  --unattended  \
--domain $IDMDomain --enable-dns-updates --all-ip-addresses --mkhomedir \
--automount-location=default  --server $IDMHOSTNAME