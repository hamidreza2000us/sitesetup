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
rhel-8-for-x86_64-baseos-eus-rpms
rhel-8-for-x86_64-appstream-eus-rpms
rhel-8-for-x86_64-highavailability-eus-rpms
ansible-2.9-for-rhel-8-x86_64-rpms
advanced-virt-for-rhel-8-x86_64-rpms
satellite-tools-6.5-for-rhel-8-x86_64-rpms
openstack-16.1-for-rhel-8-x86_64-rpms
fast-datapath-for-rhel-8-x86_64-rpms
rhceph-4-tools-for-rhel-8-x86_64-rpms
"
cat > repolistOS16 << EOF
Red Hat Enterprise Linux 8 for x86_64 - BaseOS - Extended Update Support (RPMs)
Red Hat Enterprise Linux 8 for x86_64 - AppStream - Extended Update Support (RPMs)
Red Hat Enterprise Linux 8 for x86_64 - High Availability - Extended Update Support (RPMs)
Red Hat Ansible Engine 2.9 for RHEL 8 x86_64 (RPMs)
Advanced Virtualization for RHEL 8 x86_64 (RPMs)
Red Hat Satellite Tools 6.5 for RHEL 8 x86_64 (RPMs)
Red Hat OpenStack Platform 16.1 for RHEL 8 x86_64 (RPMs)
Fast Datapath for RHEL 8 x86_64 (RPMs)
Red Hat Ceph Storage Tools 4 for RHEL 8 x86_64 (RPMs)
EOF

hammer repository-set list --organization-id 1 > RHRepoList
while read line ; do grep "$line" RHRepoList >> RHOPS16IDs ; done < repolistOS16
cat > RHOPS16IDs << EOF
9180  | yum       | Red Hat Enterprise Linux 8 for x86_64 - BaseOS - Extended Update Support (RPMs)                              
9183  | yum       | Red Hat Enterprise Linux 8 for x86_64 - AppStream - Extended Update Support (RPMs)                           
9226  | yum       | Red Hat Enterprise Linux 8 for x86_64 - High Availability - Extended Update Support (RPMs)                   
9330  | yum       | Red Hat Ansible Engine 2.9 for RHEL 8 x86_64 (RPMs)                                                          
7868  | yum       | Advanced Virtualization for RHEL 8 x86_64 (RPMs)                                                             
8693  | yum  | Red Hat Satellite Tools 6.5 for RHEL 8 x86_64 (RPMs)
9895  | yum       | Red Hat OpenStack Platform 16.1 for RHEL 8 x86_64 (RPMs)                                                     
7816  | yum       | Fast Datapath for RHEL 8 x86_64 (RPMs)                                                                       
8672  | yum       | Red Hat Ceph Storage Tools 4 for RHEL 8 x86_64 (RPMs)   
EOF



while read line  
do
  RHID=$(echo $line | awk '{print $1}')
  echo "${line}" | grep -q "Extended Update Support"
  relese="8server"
  if [[ $? == 0 ]] ; then relese="8.2" ; fi
  hammer repository-set enable --organization-id 1 --basearch x86_64 --releasever ${relese} --id $RHID ; 
done < RHOPS16IDs



hammer --output csv --no-headers repository list > enabledRepos
while read line  
do
  line=$(echo $line | awk -F\| '{print $3}' )
  line=${line/(RPMs)/RPMs}
  line=$( echo ${line} | sed 's/^ //')
  id=$(grep "${line}" enabledRepos | awk -F, '{print $1}')
  hammer repository update --organization-id 1 --mirror-on-sync false --download-policy immediate --id $id 
done <RHOPS16IDs

while read line  
do
  line=$(echo $line | awk -F\| '{print $3}' )
  line=${line/(RPMs)/RPMs}
  line=$( echo ${line} | sed 's/^ //')
  id=$(grep "${line}" enabledRepos | awk -F, '{print $1}')
  hammer repository synchronize --organization-id 1 --id $id --async
done <RHOPS16IDs

cat > RHOS16OverCloudRepo << EOF
Red Hat Enterprise Linux 8 for x86_64 - BaseOS (RPMs) Extended Update Support (EUS)
Red Hat Enterprise Linux 8 for x86_64 - AppStream (RPMs)
Red Hat Enterprise Linux 8 for x86_64 - High Availability (RPMs) Extended Update Support (EUS)
Red Hat Ansible Engine 2.9 for RHEL 8 x86_64 (RPMs)
Advanced Virtualization for RHEL 8 x86_64 (RPMs)
Red Hat Satellite Tools for RHEL 8 Server RPMs x86_64
Red Hat OpenStack Platform 16.1 for RHEL 8 (RPMs)
Red Hat Fast Datapath for RHEL 8 (RPMS)
Red Hat Ceph Storage Tools 4 for RHEL 8 x86_64 (RPMs)
Red Hat Enterprise Linux 8 for x86_64 - BaseOS (RPMs)
Red Hat Enterprise Linux 8 for x86_64 - AppStream (RPMs)
Red Hat Enterprise Linux 8 for x86_64 - High Availability (RPMs)
Red Hat Ansible Engine 2.9 for RHEL 8 x86_64 (RPMs)
Red Hat OpenStack Platform 16.1 Director Deployment Tools for RHEL 8 x86_64 (RPMs)
Red Hat Ceph Storage OSD 4 for RHEL 8 x86_64 (RPMs)
Red Hat Ceph Storage MON 4 for RHEL 8 x86_64 (RPMs)
Red Hat Ceph Storage Tools 4 for RHEL 8 x86_64 (RPMs)
Red Hat Enterprise Linux 8 for x86_64 - Real Time (RPMs)
Red Hat Enterprise Linux 8 for x86_64 - Real Time for NFV (RPMs)
EOF
while read line ; do grep "$line" RHRepoList >> RHOPS16OverCloudIDs ; done < RHOS16OverCloudRepo
#RHOPS16OverCloudIDs=$(cat RHOPS16OverCloudIDs| grep -v "^[[:space:]]*$")
while read line  
do
  RHID=$(echo $line | awk '{print $1}')
  echo "${line}" | grep -q "Extended Update Support"
  relese="8server"
  if [[ $? == 0 ]] ; then relese="8.2" ; fi
  hammer repository-set enable --organization-id 1 --basearch x86_64 --releasever ${relese} --id $RHID ; 
done < RHOPS16OverCloudIDs

hammer --output csv --no-headers repository list > enabledRepos
while read line  
do
  line=$(echo $line | awk -F\| '{print $3}' )
  line=${line/(RPMs)/RPMs}
  line=$( echo ${line} | sed 's/^ //')
  id=$(grep "${line}" enabledRepos | awk -F, '{print $1}')
  hammer repository update --organization-id 1 --mirror-on-sync false --download-policy immediate --id $id 
done <RHOPS16OverCloudIDs

while read line  
do
  line=$(echo $line | awk -F\| '{print $3}' )
  line=${line/(RPMs)/RPMs}
  line=$( echo ${line} | sed 's/^ //')
  id=$(grep "${line}" enabledRepos | awk -F, '{print $1}')
  hammer repository synchronize --organization-id 1 --id $id --async
done <RHOPS16OverCloudIDs
















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
