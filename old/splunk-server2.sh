#https://www.digiboy.ir/9726/splunk-enterprise-8-0-5-x64/#more-9726
#yum -y localinstall  http://foreman.myhost.com/pub/packages/Splunk/splunk-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm
cd /tmp
wget https://foreman.myhost.com/pub/packages/Splunk/splunk-8.1.0-Linux-x86_64.gz
tar -xvf splunk-8.1.0-Linux-x86_64.gz -C /tmp/
mv -f /tmp/splunk /opt/

groupadd splunk
useradd -d /opt/splunk -m -g splunk splunk

cat > /opt/splunk/etc/system/local/user-seed.conf  << EOF
[user_info]
USERNAME = admin
PASSWORD = changeme
EOF

chown -R splunk:splunk /opt/splunk
rm -rf /tmp/splunk.tar

firewall-cmd --zone=public --permanent --add-port=8000/tcp
firewall-cmd --zone=public --permanent --add-port=5514/udp
firewall-cmd --zone=public --permanent --add-port=9997/tcp 
firewall-cmd --zone=public --permanent --add-port=8089/tcp 
firewall-cmd --reload
sudo -u splunk /opt/splunk/bin/splunk start --accept-license
/opt/splunk/bin/splunk enable boot-start -user splunk -systemd-managed 1

sudo -u splunk /opt/splunk/bin/splunk edit licenser-localslave -master_uri 'https://192.168.13.57:8089' -auth admin:changeme
sudo -u splunk /opt/splunk/bin/splunk restart

sudo -u splunk echo "PATH=$PATH:$HOME/bin:/opt/splunk/bin" >> /opt/splunk/.bash_profile
sudo -u splunk echo "export PATH" >> /opt/splunk/.bash_profile

#/opt/splunk/bin/splunk enable listen 9997  -auth admin:changeme
