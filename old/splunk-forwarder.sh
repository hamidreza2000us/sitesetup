cd /tmp
wget https://foreman.myhost.com/pub/packages/Splunk/splunkforwarder-8.1.0-f57c09e87251-Linux-x86_64.tgz
tar -xvf splunkforwarder-8.1.0-f57c09e87251-Linux-x86_64.tgz -C /tmp

mkdir /opt
mv /tmp/splunkforwarder /opt/

groupadd splunk
useradd -d /opt/splunkforwarder -m -g splunk splunk
chown -R splunk:splunk /opt/splunkforwarder

#sudo -u splunk /opt/splunkforwarder/bin/splunk start --accept-license
/opt/splunkforwarder/bin/splunk enable boot-start -user splunk -systemd-managed 1

#sudo -u splunk /opt/splunkforwarder/bin/splunk add forward-server splunk01.myhost.com:9997 -auth admin:changeme
sudo -u splunk /opt/splunkforwarder/bin/splunk set deploy-poll splunk01.myhost.com:8089 -auth admin:changeme
sudo -u splunk /opt/splunkforwarder/bin/splunk restart

setfacl -R -m u:splunk:rx /var/log
sudo -u splunk /opt/splunkforwarder/bin/splunk add monitor /var/log/messages -index os -sourcetype syslog

sudo -u splunk echo "PATH=$PATH:$HOME/bin:/opt/splunkforwarder/bin" >> /opt/splunkforwarder/.bash_profile
sudo -u splunk echo "export PATH" >> /opt/splunkforwarder/.bash_profile

