#add mail record to idm
#ipa dnsrecord-add myhost.com mail --cname-rec myhost01
ipa dnsrecord-add myhost.com @ --mx-rec="0 mail.myhost.com."
##################################################################
#add role for client to send the mail to relay host
ansible-galaxy  install giovtorres.postfix-null-client -p /usr/share/ansible/roles/
hammer ansible roles import --role-names giovtorres.postfix-null-client --proxy-id 1
##################################################################
#add role for setup postfix mail server
ansible-galaxy  install arillso.postfix -p /usr/share/ansible/roles/
hammer ansible roles import --role-names arillso.postfix  --proxy-id 1
hammer ansible variables import --proxy-id 1
#override variable postfix mydestination
hammer ansible variables update --override true  --variable postfix_mydestination --variable-type array \
--default-value '["{{ postfix_hostname }}","$myhostname","localhost.$mydomain","localhost","$mydomain"]' \
--ansible-role  arillso.postfix  --hidden-value false  --name postfix_mydestination 
#override variable postfix mynetwork
hammer ansible variables update --override true  --variable postfix_mynetworks --variable-type array \
--default-value '["127.0.0.0/8 [::1]/128","192.168.0.0/16"]' \
--ansible-role  arillso.postfix  --hidden-value false  --name postfix_mynetworks 
#override variable for main user account
#################change name
hammer ansible variables update --override true  --variable postfix_root_mailbox --variable-type string \
--default-value "postmaster" \
--ansible-role  arillso.postfix  --hidden-value false  --name postfix_root_mailbox 
#create a user and pass , forward all root mail to him /etc/aliases
	    
##################################################################
#install role for dovecot setup
ansible-galaxy  install robertdebock.dovecot -p /usr/share/ansible/roles/
hammer ansible roles import --role-names robertdebock.dovecot  --proxy-id 1
hammer ansible variables import --proxy-id 1
#override variable for mailbox location
hammer ansible variables update --override true  --variable dovecot_mailbox_location --variable-type string \
--default-value "mbox:~/mail:INBOX=/var/spool/mail/%u" \
--ansible-role  robertdebock.dovecot --hidden-value false  --name dovecot_mailbox_location 

