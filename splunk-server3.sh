#https://www.digiboy.ir/9726/splunk-enterprise-8-0-5-x64/#more-9726
#https://download.splunk.com/products/splunk/releases/8.1.0/linux/splunk-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm
yum -y localinstall  http://foreman.myhost.com/pub/packages/Splunk/splunk-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm

cat > /opt/splunk/etc/system/local/user-seed.conf  << EOF
[user_info]
USERNAME = admin
PASSWORD = changeme
EOF

firewall-cmd --zone=public --permanent --add-port=8000/tcp
firewall-cmd --zone=public --permanent --add-port=5514/udp
firewall-cmd --zone=public --permanent --add-port=9997/tcp 
firewall-cmd --zone=public --permanent --add-port=8089/tcp 
firewall-cmd --reload

/opt/splunk/bin/splunk enable boot-start -user splunk -systemd-managed 1 --accept-license
systemctl start Splunkd
sleep 30

sudo -u splunk echo "PATH=$PATH:$HOME/bin:/opt/splunk/bin" >> /opt/splunk/.bash_profile
sudo -u splunk echo "export PATH" >> /opt/splunk/.bash_profile

sudo -u splunk /opt/splunk/bin/splunk enable listen 9997  -auth admin:changeme

curl -o /tmp/splunk-add-on-for-unix-and-linux_820.tgz http://foreman.myhost.com/pub/packages/Splunk/apps/splunk-add-on-for-unix-and-linux_820.tgz
sudo -u splunk tar -xvf /tmp/splunk-add-on-for-unix-and-linux_820.tgz -C /opt/splunk/etc/deployment-apps
sed -i '/syslog/!b;n;cdisabled = 0' /opt/splunk/etc/deployment-apps/Splunk_TA_nix/default/inputs.conf
#sed -i 's/disabled = 1/disabled = 0/g' /opt/splunk/etc/deployment-apps/Splunk_TA_nix/default/inputs.conf
#sed -i 's/disabled = true/disabled = false/g' /opt/splunk/etc/deployment-apps/Splunk_TA_nix/default/inputs.conf
sudo -u splunk cp -r /opt/splunk/etc/deployment-apps/Splunk_TA_nix/ /opt/splunk/etc/apps/

curl -o /tmp/linux-auditd-technology-add-on_310.tgz http://foreman.myhost.com/pub/packages/Splunk/apps/linux-auditd-technology-add-on_310.tgz
sudo -u splunk tar -xvf /tmp/linux-auditd-technology-add-on_310.tgz -C /opt/splunk/etc/deployment-apps
sudo -u splunk cp -r /opt/splunk/etc/deployment-apps/TA-linux_auditd/ /opt/splunk/etc/apps/

curl -o /tmp/linux-secure-technology-add-on_100.tgz http://foreman.myhost.com/pub/packages/Splunk/apps/linux-secure-technology-add-on_100.tgz
sudo -u splunk tar -xvf /tmp/linux-secure-technology-add-on_100.tgz -C /opt/splunk/etc/deployment-apps

sudo -u splunk cat > /opt/splunk/etc/system/local/serverclass.conf << EOF
[serverClass:Linux-Class]

[serverClass:Linux-Class:app:Splunk_TA_nix]
restartSplunkWeb = 0
restartSplunkd = 1
stateOnClient = enabled

[serverClass:Linux-Class]
whitelist.0 = *
EOF
chown splunk:splunk /opt/splunk/etc/system/local/serverclass.conf
chmod 600 /opt/splunk/etc/system/local/serverclass.conf
sudo -u splunk /opt/splunk/bin/splunk edit licenser-localslave -master_uri 'https://192.168.13.57:8089' -auth admin:changeme
systemctl restart Splunkd
