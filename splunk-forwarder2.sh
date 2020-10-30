#https://download.splunk.com/products/universalforwarder/releases/8.1.0/linux/splunkforwarder-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm
yum -y localinstall http://foreman.myhost.com/pub/packages/Splunk/splunkforwarder-8.1.0-f57c09e87251-linux-2.6-x86_64.rpm

firewall-cmd --zone=public --permanent --add-port=8089/tcp 
firewall-cmd --reload

cat > /opt/splunkforwarder/etc/system/local/user-seed.conf  << EOF
[user_info]
USERNAME = admin
PASSWORD = changeme
EOF

/opt/splunkforwarder/bin/splunk enable boot-start -user splunk -systemd-managed 1 --accept-license
systemctl start SplunkForwarder

sudo -u splunk /opt/splunkforwarder/bin/splunk add forward-server splunk01.myhost.com:9997 -auth admin:changeme
sudo -u splunk /opt/splunkforwarder/bin/splunk set deploy-poll splunk01.myhost.com:8089 -auth admin:changeme
systemctl restart SplunkForwarder

setfacl -R -m u:splunk:rx /var/log
#sudo -u splunk /opt/splunkforwarder/bin/splunk add monitor /var/log/messages -index main -sourcetype syslog  -auth admin:changeme

sudo -u splunk echo "PATH=$PATH:$HOME/bin:/opt/splunkforwarder/bin" >> /opt/splunkforwarder/.bash_profile
sudo -u splunk echo "export PATH" >> /opt/splunkforwarder/.bash_profile

