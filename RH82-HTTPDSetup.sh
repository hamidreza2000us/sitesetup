yum -y install httpd policycoreutils-python-utils policycoreutils-python-utils
DocRoot="/srv/myhost/www"

if [ ! -d "$DocRoot" ] ; then mkdir mkdir -p "$DocRoot" ; fi
restorecon "$DocRoot"

cat > /tmp/siteconfig << EOF
defnode mypath /files/etc/httpd/conf.d/mysite.conf
set \$mypath
set \$mypath/VirtualHost
set \$mypath/VirtualHost/arg  "_default_:80"
set \$mypath/VirtualHost/directive[1]  "DocumentRoot"
set \$mypath/VirtualHost/directive[1]/arg  '$DocRoot'
set \$mypath/Directory
set \$mypath/Directory/arg  $DocRoot
set \$mypath/Directory/directive[1]  "Require"
set \$mypath/Directory/directive[1]/arg[1]  "all"
set \$mypath/Directory/directive[1]/arg[2]  "granted"
set \$mypath/Directory/directive[2]  "AllowOverride"
set \$mypath/Directory/directive[2]/arg  "None"
save
EOF
augtool -s -f /tmp/siteconfig

if  [  $( firewall-cmd --query-service=http) == 'no'  ]
then
  firewall-cmd --permanent --add-service=http
  firewall-cmd --reload
fi

if [ $(systemctl is-enabled httpd) == 'disabled'  ]
then
  systemctl enable httpd
fi
systemctl restart httpd