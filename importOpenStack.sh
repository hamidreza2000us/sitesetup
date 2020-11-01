cat > packageList << EOF
rhel-7-server-extras-rpms
rhel-7-server-openstack-13-tools-rpms
rhel-7-server-optional-rpms
rhel-7-server-rhceph-2-tools-rpms
rhel-7-server-rh-common-rpms
rhel-7-server-rpms
rhel-7-server-supplementary-rpms
rhel-ha-for-rhel-7-server-rpms
rhel-server-rhscl-7-rpms
EOF
hammer product create --name OpenStack --label OpenStack --organization-id 1
while read line 
do 
hammer repository create   --content-type yum --organization-id 1 --product OpenStack --download-policy immediate --mirror-on-sync false \
--url http://192.168.1.150/html/redhat/$line  --name $line
hammer repository synchronize  --organization-id 1 --product OpenStack --async --name $line
done < packageList

cat > cephPackageList << EOF
MON
OSD
Tools
EOF
while read line 
do 
hammer repository create   --content-type yum --organization-id 1 --product OpenStack --download-policy immediate --mirror-on-sync false \
--url http://192.168.1.150/html/redhat/openstack/ceph/$line  --name $line
hammer repository synchronize --organization-id 1 --product OpenStack --async --name $line
done < cephPackageList

cat > openStackPackageList << EOF
rhel-7-server-openstack-13-devtools-rpms
rhel-7-server-openstack-13-optools-rpms
rhel-7-server-openstack-13-rpms
EOF
while read line 
do 
hammer repository create   --content-type yum --organization-id 1 --product OpenStack --download-policy immediate --mirror-on-sync false \
--url http://192.168.1.150/html/redhat/openstack/$line  --name $line
hammer repository synchronize --organization-id 1 --product OpenStack --async --name $line
done < openStackPackageList

hammer content-view create --name openstack --label openstack --organization-id 1 
while read line 
do 
hammer content-view add-repository --name openstack --repository $line --organization-id 1 
done < packageList
while read line 
do 
hammer content-view add-repository --name openstack --repository $line --organization-id 1 
done < cephPackageList
while read line 
do 
hammer content-view add-repository --name openstack --repository $line --organization-id 1 
done < openStackPackageList
hammer content-view publish --name openstack --organization-id 1 #--async


hammer medium create --name Redhat7.6 --os-family Redhat --path http://foreman.myhost.com/pub/cdrom --organization-id 1
hammer os create --architectures x86_64 --name Redhat --media Redhat7.6 --partition-tables "Kickstart default" --major 7 --minor 6 \
--provisioning-templates "PXELinux global default" --family "Redhat"
hammer template add-operatingsystem --name "PXELinux global default" --operatingsystem "Redhat 7.6"

hammer activation-key create --name OpenstackKey --auto-attach false --organization-id 1 --lifecycle-environment Library --content-view openstack
subid=$(hammer --output csv  subscription list | grep OpenStack | awk -F, '{print $1}' )
hammer activation-key add-subscription --name OpenstackKey --subscription-id $subid --organization-id 1

hammer hostgroup create --name hostgroup-Redhat7.6 --parent hostgroup-Redhat7.8 --medium Redhat7.6 --content-view openstack --organization-id 1 --operatingsystem "Redhat 7.6"
hammer hostgroup set-parameter --hostgroup hostgroup-Redhat7.6  --name kt_activation_keys --parameter-type string --value OpenstackKey

hammer host create --name undercloud --hostgroup hostgroup-Redhat7.6 --content-source foreman.myhost.com \
 --medium Redhat7.6 --partition-table "Kickstart default" --pxe-loader "PXELinux BIOS"  \
 --organization-id 1  --location "Default Location" --interface mac=00:50:56:2B:F9:19 \
 --build true --enabled true --managed true
