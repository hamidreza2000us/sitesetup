mkdir /mnt/iso
mount -o loop,ro ~/rhel-server-7.8-x86_64-dvd.iso /mnt/iso
mkdir -p /var/www/html/pub/sat-import/content/dist/rhel/server/7/7.8/x86_64/kickstart/
#echo -e -n "\n7.8" > /var/www/html/pub/sat-import/content/dist/rhel/server/7/listing
#echo -e -n "\nx86_64" >/var/www/html/pub/sat-import/content/dist/rhel/server/7/7.8/listing
#echo -e -n "\nkickstart"  > /var/www/html/pub/sat-import/content/dist/rhel/server/7/7.8/x86_64/listing
echo -e -n "7.8" > /var/www/html/pub/sat-import/content/dist/rhel/server/7/listing
echo -e -n "x86_64" >/var/www/html/pub/sat-import/content/dist/rhel/server/7/7.8/listing
echo -e -n "kickstart"  > /var/www/html/pub/sat-import/content/dist/rhel/server/7/7.8/x86_64/listing
cp -a /mnt/iso/* /var/www/html/pub/sat-import/content/dist/rhel/server/7/7.8/x86_64/kickstart/
cp /mnt/iso/.treeinfo /var/www/html/pub/sat-import/content/dist/rhel/server/7/7.8/x86_64/kickstart/treeinfo
chmod 744 /var/www/html/pub/sat-import/content/dist/rhel/server/7/7.8/x86_64/kickstart/treeinfo
restorecon -Rv /var/www/html/




