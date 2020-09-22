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