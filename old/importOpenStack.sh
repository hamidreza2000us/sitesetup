curl -s -H "Accept:application/json" -k -u admin:Iahoora@123 \
https://foreman.myhost.com/katello/api/v2/organizations/1/download_debug_certificate | \
awk '{print > "cert" (1+n) ".pem"} /-----END RSA PRIVATE KEY-----/ {n++}'
hammer content-credentials create --organization-id 1 --content-type cert --name DebugKey --key cert1.pem
hammer content-credentials create --organization-id 1 --content-type cert --name DebugCert --key cert2.pem

hammer repository create --name Red_Hat_Ceph_Storage_Tools_4_for_Red_Hat_Enterprise_Linux_7_Server_RPMs_x86_642 --mirror-on-sync false \
--content-type yum --url https://foreman.myhost.com/pulp/repos/behsa/Library/content/dist/rhel/server/7/7Server/x86_64/rhceph-tools/4/os/ \
--download-policy immediate --product test --organization-id 1 --ssl-client-cert DebugCert --ssl-client-key DebugKey

hammer repository synchronize --product test --name Red_Hat_Ceph_Storage_Tools_4_for_Red_Hat_Enterprise_Linux_7_Server_RPMs_x86_642 \
--organization-id 1

"
rhel-7-server-rpms
rhel-7-server-extras-rpms
rhel-7-server-rh-common-rpms
rhel-7-server-satellite-tools-6.3-rpms
rhel-ha-for-rhel-7-server-rpms
rhel-7-server-openstack-13-rpms
rhel-7-server-rhceph-3-osd-rpms
rhel-7-server-rhceph-3-mon-rpms
rhel-7-server-rhceph-3-tools-rpms
rhel-7-server-openstack-13-deployment-tools-rpms
rhel-7-server-nfv-rpms
"
cat > RedhatOfficialPackageIDs << EOF1
2456  | yum       | Red Hat Enterprise Linux 7 Server (RPMs)
3030  | yum       | Red Hat Enterprise Linux 7 Server - Extras (RPMs)
2472  | yum       | Red Hat Enterprise Linux 7 Server - RH Common (RPMs)
10269 | yum  | Red Hat Satellite Tools 6.8 (for RHEL 7 Server) (RPMs)   >>>
2762  | yum       | Red Hat Enterprise Linux High Availability (for RHEL 7 Server) (RPMs)
6671  | yum       | Red Hat OpenStack Platform 13 for RHEL 7 (RPMs)
>>>OSD
9604  | yum       | Red Hat Ceph Storage MON 3 for Red Hat Enterprise Linux 7 Server (RPMs)
6652  | yum       | Red Hat Ceph Storage Tools 3 for Red Hat Enterprise Linux 7 Server (RPMs)
>>deployment openstack
4945  | yum       | Red Hat Enterprise Linux for Real Time for NFV (RHEL 7 Server) (RPMs)
EOF1 


hammer repository-set list --organization-id 1 > RHRepoList
while read line  
do
  RHID=$(echo $line | awk '{print $1}')
  hammer repository-set enable --organization-id 1 --basearch x86_64 --releasever 7Server --id $RHID ; 
done < RedhatOfficialPackageIDs




while read id  
do
  hammer repository update --organization-id 1 --mirror-on-sync false --download-policy immediate --id $id 
done < <(hammer --output csv --no-headers repository list  | grep https://cdn.redhat.com | awk -F, '{print $1}')

while read id  
do
  hammer repository synchronize --organization-id 1 --id $id --async 
done < <(hammer --output csv --no-headers repository list  | grep https://cdn.redhat.com | awk -F, '{print $1}')

cat > packageList << EOF
rhel-7-server-extras-rpms
rhel-7-server-openstack-13-tools-rpms
rhel-7-server-optional-rpms
rhel-7-server-rhceph-2-tools-rpms
rhel-7-server-rh-common-rpms
rhel-7-server-rpms2
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
