import ovirtsdk4 as sdk
import ovirtsdk4.types as types

RHVMURL= 'rhvm.myhost.com'
RHVMUser= 'admin@internal'
RHVMPass= 'ahoora'
VMName = 'myvm2'
VMComment = "mycomment"
VMDescription = "my Description"
VMCores = 4
VMSockets = 1
VMCluster = "Default"
VMTemplate = "Blank" 
#VMTemplate = "RH83-Template"
VMMemory = 8*2**30
VMMemoryGuaranteed = 1*2**30
VMCapacity = 64*2**30
VMDomain = 'hosted_storage'
VMNetwork = 'ovirtmgmt'

connection = sdk.Connection(
    url='https://'+RHVMURL+'/ovirt-engine/api',
    username = RHVMUser,
    password = RHVMPass,
    ca_file='/etc/pki/vdsm/certs/cacert.pem',
)


# Get the reference to the "vms" service:
vms_service = connection.system_service().vms_service()

vm = types.Vm()
vm.name = VMName
vm.comment = VMComment
vm.description = VMDescription
cpu = types.CpuTopology(cores=VMCores, sockets=VMSockets)
vm.cpu= types.Cpu(topology=cpu)
vm.cluster = types.Cluster(name=VMCluster)
vm.template = types.Template(name=VMTemplate)
vm.os= types.OperatingSystem(boot=types.Boot(devices=[types.BootDevice.HD]),type='rhel_8x64')
#vm.instance_type = types.InstanceType(id="00000003-0003-0003-0003-0000000000be")
vm.memory = VMMemory
vm.time_zone = types.TimeZone(name='Asia/Tehran')
netlist =  connection.system_service().operating_systems_service().list()
for host in netlist:
    if host.name == 'rhel_8x64':
      myos=host
      print("%s (%s)" % (host.name, host.id))
vm.type = types.VmType.SERVER
vm.soundcard_enabled = False
provider = connection.system_service().external_host_providers_service().list()[0]
#vm.externalhostproviders = types.ExternalHostProvider(id='d78051b5-37c8-43bc-8eeb-04e49e59bf3')
#vm.memory_policy=types.MemoryPolicy( guaranteed=VMMemoryGuaranteed )
vms_service.add( vm )
####################################

#vms_service = connection.system_service().vms_service()
vm = vms_service.list(search='name=' + VMName)[0]
disk_attachments_service = vms_service.vm_service(vm.id).disk_attachments_service()
disk_attachment = disk_attachments_service.add(
    types.DiskAttachment(
        disk=types.Disk(
            format=types.DiskFormat.COW,
            provisioned_size=VMCapacity,
            storage_domains=[
                types.StorageDomain(
                    name=VMDomain,
                ),
            ],
        ),
        interface=types.DiskInterface.VIRTIO_SCSI,
        bootable=True,
        active=True,
    ),
)
###################################
netlist =  connection.system_service().vnic_profiles_service().list(search=VMNetwork)[0]
nics_service = vms_service.vm_service(vm.id).nics_service()
nics_service.add(
    types.Nic(
        name='nic1',
        interface=types.NicInterface.VIRTIO,
#        network=types.Network(name='ovirtmgmt'),
        vnic_profile=types.VnicProfile(id=netlist.id),
    ),
)
#################################

print("Virtual machine '%s' added." % vm.name)
print("myinfo: '%s' " % vm.id )

connection.close()
