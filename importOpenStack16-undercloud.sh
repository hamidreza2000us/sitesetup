#this script assumes that you have an online satellite server inside DMZ and another offline satellite server inside DC
#this will once sync the content to the online version and then sync the content to the offline repository
#both satellite servers need manifest installed. use the minimum amount of subscription in online version and use the rest in offline version
#identify the repositories to subscribe
PRDName=RHOSP16-undercloud
mkdir ~/${PRDName}
cd ~/${PRDName}
cat > RequestRepos << EOF
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

#list all package available by redhat to identify repositories ids
hammer repository-set list --organization-id 1 > RHRepoList
echo '' > RepoIDs

#match lines that are intented to be use by this installation
while read line ; do grep "| $line" RHRepoList >> RepoIDs-temp ; done < RequestRepos
grep -v "^$" RepoIDs-temp  | sed 's/[[:space:]]*$//g' > RepoIDs
#enable Redhat repositories that are mentioned in the list above
while read line  
do
  RHID=$(echo $line | awk '{print $1}')
  echo "${line}" | grep -q "Extended Update Support"
  relese="7server"
  newrelese=$(hammer --output csv --no-headers repository-set available-repositories --fields Release  --organization-id 1  --id $RHID | head -n1 )
  if [[ -n $newrelese ]] ; then relese="${newrelese}" ; fi
  hammer repository-set enable --organization-id 1 --basearch x86_64 --releasever ${relese} --id $RHID ; 
done <RepoIDs

#list all local enabled repositories for later use
hammer --output csv --no-headers repository list > enabledRepos

#this option is intented to use for full sync of redhat content
while read line  
do
  line=$(echo $line | awk -F\| '{print $3}' )
  line=${line/(RPMs)/RPMs}
  line=$( echo ${line} | sed 's/^ //')
  id=$(grep ",${line}" enabledRepos | awk -F, '{print $1}')
  hammer repository update --organization-id 1 --mirror-on-sync false --download-policy immediate --id $id 
done <RepoIDs

#Synchronize the Redhat Repositories
while read line  
do
  line=$(echo $line | awk -F\| '{print $3}' )
  line=$( echo ${line} | sed 's/^ //' | sed 's/(//g' | sed 's/)//g' ) 
  id=$(grep ",${line}" enabledRepos | awk -F, '{print $1}' | tail -n1) #this tail -n1 is buggy, try to fix it
  hammer repository synchronize --organization-id 1 --id $id --async
done <RepoIDs

#on the offline server do the following
#create a product 
hammer product create --name ${PRDName} --label ${PRDName} --organization-id 1
#create a content view
hammer content-view create --name "${PRDName}" --label "${PRDName}" --organization-id 1 

#read the content from online satelite and sync it
while read line  
do
  RHName=$(echo $line | awk -F\| '{print $3}' )
  RHName=$( echo ${RHName} | sed 's/^ //' | sed 's/(//g' | sed 's/)//g' ) 
  RHID=$(echo $line | awk -F\| '{print $1}' )
  id=$(grep ",${RHName}" enabledRepos | awk -F, '{print $1}'| tail -n1) #this tail -n1 is buggy, try to fix it
  #repoid=$(hammer --output csv --no-headers repository-set info --fields "Enabled Repositories/ID" --id  $RHID --organization-id 1)
  repoURL=$(hammer --output csv --no-headers repository info --fields "Published At" --id $id)
  hammer repository create --name "${RHName}" --content-type yum --organization-id 1  \
  --product "${PRDName}" --url ${repoURL} --mirror-on-sync false --ssl-client-key DebugKey --ssl-client-cert DebugCert #--download-policy immediate
  hammer content-view add-repository --product "${PRDName}"  --name "${PRDName}" --repository "${RHName}" --organization-id 1 
  hammer repository synchronize  --organization-id 1 --product "${PRDName}"  --name "${RHName}" --async
done <RepoIDs

#publish content view and make activation keys
hammer content-view publish --name "${PRDName}" --organization-id 1 --async
hammer activation-key create --name "${PRDName}" --organization-id 1 --auto-attach false --lifecycle-environment Library --content-view "${PRDName}"
SUBID=$(hammer --output csv subscription list  | grep "${PRDName}" | awk -F, '{print $1}')
hammer activation-key add-subscription --name "${PRDName}" --subscription-id ${SUBID} --organization-id 1




##################################################################################