cd /tmp
wget https://foreman.myhost.com/pub/packages/Splunk/splunk.tar
tar -xvf splunk.tar -C /tmp/
mv -f /tmp/splunk /opt/

groupadd splunk
useradd -d /opt/splunk -m -g splunk splunk

cat > /opt/splunk/etc/system/local/user-seed.conf  << EOF
[user_info]
USERNAME = admin
PASSWORD = changeme
EOF

wget https://foreman.myhost.com/pub/packages/Splunk/Splunk-fix.tar 
tar -xvf Splunk-fix.tar -C /tmp
mv -f /tmp/Splunk-fix/splunkd /opt/splunk/bin/

chown -R splunk:splunk /opt/splunk
rm -rf /tmp/splunk-fix.tar
rm -rf /tmp/splunk.tar

firewall-cmd --zone=public --permanent --add-port=8000/tcp
firewall-cmd --zone=public --permanent --add-port=5514/udp
firewall-cmd --zone=public --permanent --add-port=9997/tcp 
firewall-cmd --reload
sudo -u splunk /opt/splunk/bin/splunk start --accept-license
/opt/splunk/bin/splunk enable boot-start

sudo -u splunk /opt/splunk/bin/splunk add license /tmp/Splunk-fix/splunk-enterprise.lic -auth admin:changeme
sudo -u splunk /opt/splunk/bin/splunk restart

