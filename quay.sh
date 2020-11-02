#this script is tested with RH7.8 
#it requires a server with 4 cores and 4 GB of memory
#enough disk space is required
#you should already import the images and also add the repository to install docker
http://foreman.myhost.com/pub/images/mysql-57-rhel7.tar.gz
http://foreman.myhost.com/pub/images/quay_v3.3.0.tar.gz
http://foreman.myhost.com/pub/images/redis-32-rhel7.tar.gz

yum install -y docker mariadb telnet
systemctl enable docker --now

firewall-cmd --permanent --add-port=8443/tcp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --add-service=mysql --permanent
firewall-cmd --permanent --add-port=6379/tcp
firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload

docker load -i mysql-57-rhel7.tar.gz
docker load -i redis-32-rhel7.tar.gz
docker load -i quay_v3.3.0.tar.gz

mkdir -p /var/lib/mysql
chmod 777 /var/lib/mysql
export MYSQL_CONTAINER_NAME=mysql
export MYSQL_DATABASE=enterpriseregistrydb
export MYSQL_PASSWORD=ahoora
export MYSQL_USER=quayuser
export MYSQL_ROOT_PASSWORD=ahoora
docker run --detach --restart=always --env MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} --env MYSQL_USER=${MYSQL_USER}  \
--env MYSQL_PASSWORD=${MYSQL_PASSWORD} --env MYSQL_DATABASE=${MYSQL_DATABASE} --name ${MYSQL_CONTAINER_NAME} --privileged=true \
--publish 3306:3306  -v /var/lib/mysql:/var/lib/mysql/data:Z  registry.access.redhat.com/rhscl/mysql-57-rhel7

docker run -d --restart=always -p 6379:6379  --privileged=true  -v /var/lib/redis:/var/lib/redis/data:Z \
registry.access.redhat.com/rhscl/redis-32-rhel7

openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem -subj \
"/C=GR/ST=Frankfurt/L=Frankfurt/O=SanCluster/CN=quay.myhost.com"

IP=${IP:="$(ip route get 8.8.8.8 | awk '{print $7; exit}')"}
hostname=$(hostname -f)

cat >  openssl.cnf << EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${hostname}
IP.1 = ${IP}
EOF

openssl genrsa -out ssl.key 2048
openssl req -new -key ssl.key -out ssl.csr -subj "/CN=quay-enterprise" -config openssl.cnf
openssl x509 -req -in ssl.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out ssl.cert -days 356 -extensions v3_req -extfile openssl.cnf

mkdir -p /etc/docker/certs.d/quay.myhost.com/ #change to the hostname
cp rootCA.pem /etc/docker/certs.d/quay.myhost.com/ca.crt #change to the hostname
mkdir -p /mnt/quay/config
chmod 777 /mnt/quay/config
mkdir -p /mnt/quay/storage
chmod 777 /mnt/quay/storage
docker run --privileged=true -p 8443:8443 -d quay.myhost.com/admin/quay:v3.3.0 config ${MYSQL_PASSWORD} quay.myhost.com/admin/quay:v3.3.0
cp ssl.cert ssl.crt


echo "###########################################"
echo "Download the ssl.key and ssl.cert to your desktop"
echo "Pleae open a web browser with this address:"
echo "https://$(hostname -f):8443"
echo "Username is: quayconfig"
echo "Password is: ${MYSQL_PASSWORD}"
echo "###########################################"
echo -n " "
echo "###########################################"
echo "Click on start new registory setup"
echo "Database type is Mysql"
echo "Database Server: $(hostname -f)"
echo "Username: ${MYSQL_USER}"
echo "Pasword: ${MYSQL_PASSWORD}"
echo "Databse Name: ${MYSQL_DATABASE}"
echo "###########################################"
echo "Enter your desired credentials"
echo "###########################################"
echo "Server Hostname: $(hostname -f)"
echo "TLS: Red Hat Quay handles TLS"
echo "Certificate: ssl.cert"
echo "Private Key: ssl.key"
echo "Redis Hostname:  $(hostname -f)"
echo "Save Configuration Changes"
echo "Download Configuration from the browser and upload to the linux server"
echo "###########################################"
echo -n " "
echo -n " "
echo "###########################################"
echo "Then enter the following commands manually"
echo "cp quay-config.tar.gz /mnt/quay/config/"
echo "cd /mnt/quay/config/"
echo "tar xvf quay-config.tar.gz"
echo "docker run --restart=always -p 443:8443 -p 80:8080 --sysctl net.core.somaxconn=4096 --privileged=true \
-v /mnt/quay/config:/conf/stack:Z -v /mnt/quay/storage:/datastorage:Z -d quay.myhost.com/admin/quay:v3.3.0"
echo "###########################################"
echo "login to you quay server with address below:"
echo "https://$(hostname -f)"

#docker run -d --name mirroring-worker2 -v /mnt/quay/config:/conf/stack -v \
#/root/ca.crt:/etc/pki/ca-trust/source/anchors/ca.crt quay.myhost.com/admin/quay:v3.3.0 repomirror

cat > dockerImages << EOF
registry.access.redhat.com/rhosp13/openstack-aodh-api:latest
registry.access.redhat.com/rhosp13/openstack-aodh-evaluator:latest
registry.access.redhat.com/rhosp13/openstack-aodh-listener:latest
registry.access.redhat.com/rhosp13/openstack-aodh-notifier:latest
registry.access.redhat.com/rhosp13/openstack-ceilometer-central:latest
registry.access.redhat.com/rhosp13/openstack-ceilometer-compute:latest
registry.access.redhat.com/rhosp13/openstack-ceilometer-notification:latest
registry.access.redhat.com/rhosp13/openstack-cinder-api:latest
registry.access.redhat.com/rhosp13/openstack-cinder-scheduler:latest
registry.access.redhat.com/rhosp13/openstack-cinder-volume:latest
registry.access.redhat.com/rhosp13/openstack-cron:latest
registry.access.redhat.com/rhosp13/openstack-glance-api:latest
registry.access.redhat.com/rhosp13/openstack-gnocchi-api:latest
registry.access.redhat.com/rhosp13/openstack-gnocchi-metricd:latest
registry.access.redhat.com/rhosp13/openstack-gnocchi-statsd:latest
registry.access.redhat.com/rhosp13/openstack-haproxy:latest
registry.access.redhat.com/rhosp13/openstack-heat-api-cfn:latest
registry.access.redhat.com/rhosp13/openstack-heat-api:latest
registry.access.redhat.com/rhosp13/openstack-heat-engine:latest
registry.access.redhat.com/rhosp13/openstack-horizon:latest
registry.access.redhat.com/rhosp13/openstack-iscsid:latest
registry.access.redhat.com/rhosp13/openstack-keystone:latest
registry.access.redhat.com/rhosp13/openstack-mariadb:latest
registry.access.redhat.com/rhosp13/openstack-memcached:latest
registry.access.redhat.com/rhosp13/openstack-neutron-dhcp-agent:latest
registry.access.redhat.com/rhosp13/openstack-neutron-l3-agent:latest
registry.access.redhat.com/rhosp13/openstack-neutron-metadata-agent:latest
registry.access.redhat.com/rhosp13/openstack-neutron-openvswitch-agent:latest
registry.access.redhat.com/rhosp13/openstack-neutron-server:latest
registry.access.redhat.com/rhosp13/openstack-nova-api:latest
registry.access.redhat.com/rhosp13/openstack-nova-compute:latest
registry.access.redhat.com/rhosp13/openstack-nova-conductor:latest
registry.access.redhat.com/rhosp13/openstack-nova-consoleauth:latest
registry.access.redhat.com/rhosp13/openstack-nova-libvirt:latest
registry.access.redhat.com/rhosp13/openstack-nova-novncproxy:latest
registry.access.redhat.com/rhosp13/openstack-nova-placement-api:latest
registry.access.redhat.com/rhosp13/openstack-nova-scheduler:latest
registry.access.redhat.com/rhosp13/openstack-octavia-api:latest
registry.access.redhat.com/rhosp13/openstack-octavia-health-manager:latest
registry.access.redhat.com/rhosp13/openstack-octavia-housekeeping:latest
registry.access.redhat.com/rhosp13/openstack-octavia-worker:latest
registry.access.redhat.com/rhosp13/openstack-panko-api:latest
registry.access.redhat.com/rhosp13/openstack-rabbitmq:latest
registry.access.redhat.com/rhosp13/openstack-redis:latest
registry.access.redhat.com/rhosp13/openstack-swift-account:latest
registry.access.redhat.com/rhosp13/openstack-swift-container:latest
registry.access.redhat.com/rhosp13/openstack-swift-object:latest
registry.access.redhat.com/rhosp13/openstack-swift-proxy-server:latest
registry.access.redhat.com/rhceph/rhceph-3-rhel7:latest
EOF

while read line ; do docker pull $line ; done < dockerImages

while read line 
do 
  image=$(echo $line | awk '{print $1}') 
  tag=$(echo $line | awk '{print $2}') 
  imageRename=$(echo $image | sed "s/registry.access.redhat.com/quay.myhost.com/g") 
  id=$(echo $line | awk '{print $3}')
  docker tag $id $imageRename:$tag  
  docker push $imageRename:$tag  
done <  <( docker images | grep "registry.access.redhat.com" )