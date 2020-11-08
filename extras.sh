#sample for add new repository to satellite and content view
hammer repository   create  --name "RHExtra"    --content-type yum  --organization-id 1  \
--product RH --url http://sat.myhost.com/pub/export/sat-tools/ --download-policy immediate --mirror-on-sync false
hammer repository synchronize  --organization-id 1 --product RH  --name "RHExtra" #--async
hammer content-view add-repository --name contentview01 --repository "RHExtra" --organization-id 1 
hammer content-view publish --name contentview01 --organization-id 1 #--async
hammer content-view  version promote --organization-id 1  --content-view contentview01 --to-lifecycle-environment dev  --version 2.0

00:0C:29:AF:49:25

hammer host create --name myhost02 --hostgroup hostgroup01 --content-source foreman.myhost.com \
 --medium RH7.7 --partition-table "Kickstart default" --pxe-loader "PXELinux BIOS"  \
 --organization-id 1  --location "Default Location" --interface mac=00:0C:29:AF:49:25 \
 --build true --enabled true --managed true
 
 
cat > RedhatOfficialPackageIDs << EOF1
2808  | yum  | Red Hat Software Collections RPMs for Red Hat Enterprise Linux 7 Server
2762  | yum       | Red Hat Enterprise Linux High Availability (for RHEL 7 Server) (RPMs)
9604  | yum       | Red Hat Ceph Storage MON 3 for Red Hat Enterprise Linux 7 Server (RPMs)
6652  | yum       | Red Hat Ceph Storage Tools 3 for Red Hat Enterprise Linux 7 Server (RPMs)
9601  | yum       | Red Hat Ceph Storage Tools 4 for Red Hat Enterprise Linux 7 Server (RPMs)
4115  | yum       | Red Hat Enterprise Linux 7 Server - Extended Update Support - Optional (RPMs)
4117  | yum       | Red Hat Enterprise Linux 7 Server - Extended Update Support (RPMs)
4138  | yum       | Red Hat Enterprise Linux 7 Server - Extended Update Support - Supplementary (RPMs)
3030  | yum       | Red Hat Enterprise Linux 7 Server - Extras (RPMs)
2463  | yum       | Red Hat Enterprise Linux 7 Server - Optional (RPMs)
2472  | yum       | Red Hat Enterprise Linux 7 Server - RH Common (RPMs)
2456  | yum       | Red Hat Enterprise Linux 7 Server (RPMs)
2476  | yum       | Red Hat Enterprise Linux 7 Server - Supplementary (RPMs)
6678  | yum       | Red Hat OpenStack Platform 13 Developer Tools for RHEL 7 (RPMs)
6671  | yum       | Red Hat OpenStack Platform 13 for RHEL 7 (RPMs)
10057 | yum       | Red Hat OpenStack Platform 13 Octavia for RHEL 7 (RPMs)
6675  | yum       | Red Hat OpenStack Platform 13 Operational Tools for RHEL 7 (RPMs)
6683  | yum       | Red Hat OpenStack Platform 13 Tools for RHEL 7 Server (RPMs)

9318  | yum       | Red Hat Ansible Engine 2.9 RPMs for Red Hat Enterprise Linux 7 Server
4945  | yum       | Red Hat Enterprise Linux for Real Time for NFV (RHEL 7 Server) (RPMs)
10269 | yum  | Red Hat Satellite Tools 6.8 (for RHEL 7 Server) (RPMs)
EOF1

