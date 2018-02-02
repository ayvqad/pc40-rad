#RightScale Cloud Application Template (CAT)

# DESCRIPTION
# Deploys a basic Linux server of type CentOS
# If needed by the target cloud, the security group and/or ssh key is automatically created by the CAT.
#
# DEPENDENCIES
#
#

# Required prolog
name 'QAD Linux Server'
rs_ca_ver 20160622
short_description "![logo](http://www.qad.com/documents/hosted-images/os-logos/cent-os-logo.png) Base Linux server using SaltStack"
long_description "Launches a base Linux server using SaltStack to configure it on deployment\n\n
Clouds Supported: <B>VMware</B>"

import "pft/parameters"
import "pft/mappings"
import "pft/resources", as: "common_resources"
import "pft/conditions"
import "pft/server_templates_utilities"
import "pft/cloud_utilities"
import "pft/account_utilities"
import "pft/volume_mappings"

##################
# User inputs    #
##################

parameter "param_location" do

  like $parameters.param_location

end

parameter "param_os_version" do

  category "Deployment Options"
  label "Operating System"
  type "string"
  allowed_values "CentOS 7.4", "CentOS 6.9"
  default "CentOS 7.4"

end

parameter "param_instancetype" do
  category "Deployment Options"
  label "Server Resource Profile (approximate)"
  type "list"
  allowed_values "1CPU-16GB","2CPU-16GB", "2CPU-32GB", "4CPU-64GB"
  default "2CPU-16GB"
end

#put pattern evaluation in backup name
parameter "param_lineage_name" do

    category "User Inputs"
    label "Volume Backup Name"
    description "Provide a name for this volume backup"
    type "string"
    min_length 8
    max_length 63
    allowed_pattern "^[a-z0-9-]{8,64}$"
    constraint_description "Volume backup names are 8-63 characters and can contain lowercase letters (a-z), numbers (0-9), and dashes (-)."
end

#moved parameter from CAT to LIB
parameter "param_disk_content" do

    like $volume_mappings.volume_backups

end


################################
# Outputs returned to the user #
################################
output "ssh_link" do

  label "SSH Link"
  category "Output"
  description "Use this string to access your server."

end


##############
# MAPPINGS   #
##############
mapping "map_cloud" do

  like $mappings.map_cloud

end

mapping "map_instancetype" do

  like $mappings.map_instancetype

end

mapping "map_st" do {

  "linux_server" => {
    "name" => "QAD All Base Linux SaltStack",
    "rev" => "1",
  },
}

end

mapping "map_mci" do {
   "CentOS 7.4" => {
      "CentOS_mci" => "QAD CentOS 7.4 Base",
      "CentOS_mci_rev" => "6" },
   "CentOS 6.9" => {
      "CentOS_mci" => "QAD CentOS 6.9 Base",
      "CentOS_mci_rev" => "6" } }
end

#moved mapping from CAT to LIB (ayv)
mapping "attached_disk_content" do

   like $volume_mappings.map_backups

end


##################
# CONDITIONS     #
##################

# Used to decide whether or not to pass an SSH key or security group when creating the servers.
condition "needsSshKey" do

  like $conditions.needsSshKey

end

condition "needsSecurityGroup" do

  like $conditions.needsSecurityGroup

end

condition "needsPlacementGroup" do

  like $conditions.needsPlacementGroup

end

condition "invSphere" do

  like $conditions.invSphere

end

condition "inAzure" do

  like $conditions.inAzure

end

############################
# RESOURCE DEFINITIONS     #
############################

### Server Definition ###
# QAD - Key updates
# server_template_href 'specifically naming the HREF from Server Template Info tab'

resource "linux_server", type: "server" do

  name join(['Linux Server-',last(split(@@deployment.href,"/"))])
  cloud map($map_cloud, $param_location, "cloud")
  datacenter map($map_cloud, $param_location, "zone")
  server_template_href find(map($map_st, "linux_server", "name"), revision: map($map_st, "linux_server", "rev"))
  multi_cloud_image_href find(map($map_mci, $param_os_version, "CentOS_mci"), revision: map($map_mci, $param_os_version, "CentOS_mci_rev"))
  instance_type map($map_instancetype, $param_instancetype, $param_location)
  ssh_key_href map($map_cloud, $param_location, "ssh_key")
  security_group_hrefs map($map_cloud, $param_location, "sg")
  placement_group_href map($map_cloud, $param_location, "pg")

  inputs do {
   "ENABLE_AUTO_UPGRADE" => "text:false",
   "OS_VERSION" => join(["text:",$param_os_version,""]),
   "LINEAGE" => "text:qadapps-dr01-empty",
   "DISK_CONTENT" => join(["text:",$param_disk_content,""]),
   "SERVER_HOSTNAME" => "text:vmlinux.qad.com"
  } end

end

resource "sec_group", type: "security_group" do

  condition $needsSecurityGroup
  like @common_resources.sec_group

end

resource "sec_group_rule_ssh", type: "security_group_rule" do

  condition $needsSecurityGroup
  like @common_resources.sec_group_rule_ssh

end

resource "ssh_key", type: "ssh_key" do

  condition $needsSshKey
  like @common_resources.ssh_key

end

resource "placement_group", type: "placement_group" do

  condition $needsPlacementGroup
  like @common_resources.placement_group

end

resource "dr01", type: "volume" do
  name join(["Linux_Server_", last(split(@@deployment.href,"/")), "_dr01"])
  datacenter map($map_cloud, $param_location, "zone")
  cloud map($map_cloud, $param_location, "cloud")
  parent_volume_snapshot_href map($attached_disk_content, $param_disk_content, "Disk")
  size 100
  volume_type "standard"
end

resource "attach_dr01", type: "volume_attachment" do
  name "Attach Volume dr01"
  volume @dr01
  instance @linux_server
  cloud map($map_cloud, $param_location, "cloud")
  device "lsiLogic(1:0)"
end

resource "swap", type: "volume" do
  name join([ "Linux_Server_", last(split(@@deployment.href,"/")), "_swap"])
  datacenter map($map_cloud, $param_location, "zone")
  cloud map($map_cloud, $param_location, "cloud")
  size 15
  volume_type "standard"
end

resource "attach_swap", type: "volume_attachment" do
  name "Attach Volume swap"
  volume @swap
  instance @linux_server
  cloud map($map_cloud, $param_location, "cloud")
  device "lsiLogic(2:0)"
end

##################
# Permissions    #
##################
permission "import_servertemplates" do

  like $server_templates_utilities.import_servertemplates

end


####################
# OPERATIONS       #
####################
operation "launch" do

  description "Launch the server"
  definition "pre_auto_launch"

end

operation "enable" do

  description "Get information once the app has been launched"
  definition "enable"

  # Update the links provided in the outputs.
  output_mappings do {
    $ssh_link => join(["ssh://rightscale@",$server_ip_address]),
    # $qad_ui => join(["https://",$server_ip_address,":22011/qad-central"])
  } end

end

operation "stop" do

  description "Stop and delete the VM instance; keep the persistent disks and data for next use"
  definition "stop"

end

operation "start" do

  description "Create the VM instance from the existing disks and data"
  definition "start"

  # Update the links provided in the outputs.
  output_mappings do {
    $ssh_link => join(["ssh://rightscale@",$server_ip_address]),
    # $qad_ui => join(["https://",$server_ip_address,":22011/qad-central"])
  } end

end

operation "terminate" do

  description "Delete the VM instance and destroy all associated resources (disks, networks, settings) - Snapshots are not destroyed through this process"
  definition "pre_auto_terminate"

end

operation "backup" do

    description "Create a backup of the dr01 volume only"
    definition "backup_main"
    label "Backup the /dr01 Volume"
end

##########################
# DEFINITIONS (i.e. RCL) #
##########################

# Define the "stop" behavior
define stop(@linux_server) return @linux_server do

  # Issue the stop, which deletes the instance, without deleting the persistent disks
  @linux_server.current_instance().stop()

end

# Define the "start" behavior - return the new server IP address link
define start(@linux_server) return @linux_server, $server_ip_address do

  # Create the VM instance from the current windows_server deployment
  @linux_server.current_instance().start()

  # Retrieve the server IP address
    #Get the appropriate IP address depending on the environment

    while equals?(@linux_server.current_instance().public_ip_addresses[0], null) do
      sleep(10)
    end
    $server_addr =  @linux_server.current_instance().public_ip_addresses[0]

    $tag_value = tag_value(@linux_server.current_instance(), "server:public_ip_0")
    if $tag_value == null
      $tag_value = "unknown"
    end

    # If deployed in Azure one needs to provide the port mapping that Azure uses
    if $inAzure
       @bindings = rs_cm.clouds.get(href: @linux_server.current_instance().cloud().href).ip_address_bindings(filter: ["instance_href==" + @linux_server.current_instance().href])
       @binding = select(@bindings, {"private_port":22})
       $server_ip_address = join(["-p ", @binding.public_port, " rightscale@", to_s(@linux_server.current_instance().public_ip_addresses[0])])
    else
      # If not in Azure, then we can actually provide the SSH link like that found in CM
      $server_ip_address = $server_addr
    end

end

# Import and set up what is needed for the server and then launch it.
define pre_auto_launch($map_cloud, $param_location, $invSphere, $map_st) do

    # Need the cloud name later on
    $cloud_name = map( $map_cloud, $param_location, "cloud" )

    # Check if the selected cloud is supported in this account.
    # Since different PIB scenarios include different clouds, this check is needed.
    # It raises an error if not which stops execution at that point.
    call cloud_utilities.checkCloudSupport($cloud_name, $param_location)

    # Find and import the server template - just in case it hasn't been imported to the account already
    call server_templates_utilities.importServerTemplate($map_st)
end

# Enable function will only run upon build/creation of the environment (or restart from terminated state)
define enable(@linux_server, $inAzure, $invSphere) return $server_ip_address do

    # Tag the servers with the selected project cost center ID
    #$tags=[join(["costcenter:id=",$param_costcenter])]
    #rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: $tags)
    #rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: ["rs_backup:lineage=qadapps-dr01-empty"])

    #Get the appropriate IP address depending on the environment
    while equals?(@linux_server.current_instance().public_ip_addresses[0], null) do
      sleep(10)
    end
    $server_addr =  @linux_server.current_instance().public_ip_addresses[0]

    $tag_value = tag_value(@linux_server.current_instance(), "server:public_ip_0")
    if $tag_value == null
      $tag_value = "unknown"
    end

    # If deployed in Azure one needs to provide the port mapping that Azure uses
    if $inAzure
       @bindings = rs_cm.clouds.get(href: @linux_server.current_instance().cloud().href).ip_address_bindings(filter: ["instance_href==" + @linux_server.current_instance().href])
       @binding = select(@bindings, {"private_port":22})
       $server_ip_address = join(["-p ", @binding.public_port, " rightscale@", to_s(@linux_server.current_instance().public_ip_addresses[0])])
    else
      # If not in Azure, then we can actually provide the SSH link like that found in CM
      $server_ip_address = $server_addr
    end
	#Mount swap
	call server_templates_utilities.run_script_no_inputs(@linux_server, "QAD All - Mount Swap Volume")

	#Mount dr01
	call server_templates_utilities.run_script_no_inputs(@linux_server, "QAD All - Mount dr01 Volume")

end

define backup_main(@linux_server, @attach_dr01, $param_lineage_name) return @backup,$vol_attachment_hrefs do

  $instance_href = @linux_server.current_instance().href
  call account_utilities.getUserLogin() retrieve $userlogin
  $param_backup_name = join([$userlogin, " - Linux_Server_", last(split(@@deployment.href,"/")), " - backup_dr01"])
  call get_vol_attachment_hrefs(@attach_dr01) retrieve $volume_attachment_hrefs
  call create_backup($volume_attachment_hrefs, $param_lineage_name, $param_backup_name, $userlogin) retrieve @backup

end

define get_vol_attachment_hrefs(@attach_dr01) return $volume_attachment_hrefs do

  #We just want @dr01 backed up
  @volume_attachment = rs_cm.get(href: @attach_dr01)
  $volume_attachment_hrefs = @volume_attachment.href[]

end

define create_backup($volume_attachment_hrefs, $param_lineage_name, $param_backup_name, $userlogin) return @backup do

  rs_cm.backups.create(backup: {"volume_attachment_hrefs": $volume_attachment_hrefs, "lineage": $param_lineage_name, "name": $param_backup_name})
  @backup = rs_cm.backups.index(lineage: $param_lineage_name)

end

define pre_auto_terminate(@linux_server) do

  call server_templates_utilities.run_script_no_inputs(@linux_server, "QAD All - Remove SaltStack minion on decommission")

end
