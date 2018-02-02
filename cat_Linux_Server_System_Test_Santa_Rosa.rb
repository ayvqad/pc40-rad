#RightScale Cloud Application Template (CAT)

# DESCRIPTION
# Deploys a basic Linux server of type CentOS
# If needed by the target cloud, the security group and/or ssh key is automatically created by the CAT.
#
# FIXED VARIABLES USED FOR THIS CAT
# Mount (device) Snapshot Image "snapshot name"
#
# /qad  (sdc)    "qad-cache-area"
# /dr01 (sdd)    from list items in LIB pft/snapshots_systest
#
# NETWORK SECURITY GROUP RULES
# from lib_common_resources
# sec_group_rule_qadui (tcp:22000-22100)
# sec_group_rule_qadtomcat (tcp:8080)
# sec_group_rule_qadqxtend (tcp:8090)
# sec_group_rule_qadsambatcp (tcp:137,138,445)
# sec_group_rule_qadsambaudp (udp:139,445)
#
# SEE BELOW FOR DEFINITIONS RELATED TO
# - USER INPUTS, USER OUTPUTS
# - OPERATIONS (Standard Start, Stop, Enable, Pre-Start, Pre-Terminate)
# - Custom OPERATIONS (take_snapshot)

# CHANGE LOG
# DCOPM-357 Create security group rules for SAMBA
# Publishing Server Template rev 15
# --- Update the revision of Server Template/Images (in CAT)
# --- Update INPUT parameters (in CAT)

# Required prolog
name 'System Test Santa Rosa 2 - Pre-built Environments'
rs_ca_ver 20160622
short_description "![Linux] (http://www.qad.com/documents/hosted-images/os-logos/linux-logo.png) ![CentOS] (http://www.qad.com/documents/hosted-images/os-logos/cent-os-logo.png) ![QAD] (http://www.qad.com/documents/hosted-images/os-logos/qad-logo-small.png) \n
Deploy a Linux Server Environment from Pre-Built System Test Recipes"
long_description "Launches a Linux server based on pre-built recipes\n
\n
Clouds Supported: <B>Google, VMware</B>"

import "pft/parameters"
import "pft/mappings"
import "pft/resources", as: "common_resources"
import "pft/conditions"
import "pft/server_templates_utilities"
import "pft/cloud_utilities"
import "pft/snapshots_systest"
import "pft/account_utilities"

##################
# User inputs    #
##################

parameter "param_location" do

  like $parameters.param_location

end

parameter "param_servertype" do
   category "User Inputs"
   label "Linux Server Type"
   type "list"
   description "Type of Linux server to launch"
   allowed_values "CentOS"
   default "CentOS"
end

# To allow user selection for instance type - otherwise just hardcode value in resource linux_server call

parameter "param_instancetype" do

  like $parameters.param_instancetype

end

parameter "param_costcenter" do

  like $parameters.param_costcenter

end

parameter "param_rdsystest_image" do

   like $snapshots_systest.param_rdsystest_image

end

parameter "param_server_lineage" do

    category "User Inputs"
    label "Provide a name to help create and identify your snapshots, like a release test name or other meaningful value"
    type "string"
    min_length 8
    max_length 63
    allowed_pattern "^[a-z0-9-]{8,64}$"
    constraint_description "Snapshot names are 8-63 characters and can contain lowercase letters (a-z), numbers (0-9), and dashes (-)."

end

#parameter "param_mount_point" do
#
#    category "User Inputs"
#    label "Mount point directory for backup"
#    type "string"
#    default "/dr01"
#    allowed_pattern "^\/[a-z0-9\_\-]{3,20}$"
#    constraint_description "Mount directory names are 3-20 characters and can contain lowercase letters (a-z), numbers (0-9), dashes (-) and underscores (_)"
#
#end

################################
# Outputs returned to the user #
################################
output "ssh_link" do

  label "SSH Link"
  category "Output"
  description "Use this link to access your server."

end

output "qad_netui_install" do

    label "NetUI Install"
    category "Output"
    description "Use this link to download QAD .NetUI installer"

end

output "qad_ci_access" do

    label "QAD Channel Islands Access"
    category "Output"
    description "Use this link to access QAD Channel Islands (make sure services are started)"

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

# QAD - Looking for a server template matching the name below, but overridden by server_template_href
# not quite sure about this one - can't delete as map_st is expected
mapping "map_st" do {

  "linux_server" => {
    "name" => "QAD All Base Linux",
    "rev" => "15",
  },
}

end

# QAD - Mapping to Images to be used in the different clouds -> Note QAD RightImage for VMware
# See Server Template -> Images
mapping "map_mci" do {

  "VMware" => { # vSphere
    "CentOS_mci" => "RightImage10_CentOS_6.9_x64",
    "CentOS_mci_rev" => "0"
  },
  "Public" => { # all other clouds
    "CentOS_mci" => "RightImage10_CentOS_6.9_x64",
    "CentOS_mci_rev" => "4"
  }
}

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

  #name join(['vmlinux-',last(split(@@deployment.href,"/"))])
  name "vmlinux"
  cloud map($map_cloud, $param_location, "cloud")
  datacenter map($map_cloud, $param_location, "zone")
  server_template_href find(map("map_st", "linux_server", "name"), revision: map("map_st", "linux_server", "rev"))
  multi_cloud_image_href find(map($map_mci, map($map_cloud, $param_location, "mci_mapping"), "CentOS_mci"), revision: map($map_mci, map($map_cloud, $param_location, "mci_mapping"), "CentOS_mci_rev"))
  #instance_type map($map_instancetype, $param_instancetype, $param_location)
  instance_type map($map_instancetype, $param_instancetype, $param_location)
  ssh_key_href map($map_cloud, $param_location, "ssh_key")
  security_group_hrefs map($map_cloud, $param_location, "sg")
  placement_group_href map($map_cloud, $param_location, "pg")

  inputs do {
    "ENABLE_AUTO_UPGRADE" => "text:false",
    "LINEAGE" => join(['text:', $param_rdsystest_image], ""),
    "MOUNTPOINT" => "text:/dr01",
    "DRIVE_TYPE" => "text:SSD",
    "SERVER_HOSTNAME" => "text:vmlinux.qad.com"
  } end

end

### Security Group Definitions ###
# Note: Even though not all environments need or use security groups, the launch operation/definition will decide whether or not
# to provision the security group and rules.
resource "sec_group", type: "security_group" do

  condition $needsSecurityGroup
  like @common_resources.sec_group

end

# Security Group Rule for SSH
resource "sec_group_rule_ssh", type: "security_group_rule" do

  condition $needsSecurityGroup
  like @common_resources.sec_group_rule_ssh

end

# Security Group Rule for QAD UI
resource "sec_group_rule_qadui", type: "security_group_rule" do

  condition $needsSecurityGroup
  like @common_resources.sec_group_rule_qadui

end

# Security Group Rule for QAD Tomcat
resource "sec_group_rule_qadtomcat", type: "security_group_rule" do

  condition $needsSecurityGroup
  like @common_resources.sec_group_rule_qadtomcat

end

# Security Group Rule for QAD QXtend
resource "sec_group_rule_qadqxtend", type: "security_group_rule" do

  condition $needsSecurityGroup
  like @common_resources.sec_group_rule_qadqxtend

end

# Security Group Rule(s) for SAMBA Sharing

#resource "sec_group_rule_qadsambatcp", type: "security_group_rule" do
#
#    condition $needsSecurityGroup
#    like @common_resources.sec_group_rule_qadsambatcp
#
#end

#resource "sec_group_rule_qadsambaudp", type: "security_group_rule" do
#
#    condition $needsSecurityGroup
#    like @common_resources.sec_group_rule_qadsambaudp
#
#end


### SSH Key ###
resource "ssh_key", type: "ssh_key" do

  condition $needsSshKey
  like @common_resources.ssh_key

end

### Placement Group ###
resource "placement_group", type: "placement_group" do

  condition $needsPlacementGroup
  like @common_resources.placement_group

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
    $qad_netui_install => "http://vmlinux.qad.com:22000/qadhome",
    $qad_ci_access => "https://vmlinux.qad.com:22011/qad-central"

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
    $qad_netui_install => "http://vmlinux.qad.com:22000/qadhome",
    $qad_ci_access => "http://vmlinux.qad.com:22010/qad-central"

  } end

end

# operation "attach_disk" do
#
#    description "Attach a new empty disk"
#    definition "attach_volume"
#
# end

operation "take_snapshot" do

    description "Create a snapshot of attached disk"
    definition "take_snapshot"

end

# operation "restore_from_snapshot" do

#  description "Restore and attach disk from snapshot"
#  definition "restore_from_snapshot"

# end

#operation "create_qad_local_accounts" do
#
#    description "Create QAD Product User Accounts, Groups & permissions"
#    definition "create_qad_local_accounts"
#
#end

# operation "update_server_password" do
#
#  label "Update Admin Password"
#  description "Update/reset the Admin password."
#  definition "update_password"
#
# end

# operation "terminate" do
#  description "Delete the VM instance and destroy all associated resources (disks, networks, settings)"
#  definition "pre_auto_terminate"
# end

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

    # Create the Admin Password credential used for the server based on the user-entered password.
    # $credname = join(["CAT_WINDOWS_ADMIN_PASSWORD-",@@deployment.href])
    # rs_cm.credentials.create({"name":$credname, "value": $param_password})

end

define enable(@linux_server, $param_costcenter, $inAzure, $invSphere, $param_rdsystest_image) return $server_ip_address do

    task_label("Determining Server IP address")

    # Tag the servers with the selected project cost center ID
    $tags=[join(["costcenter:id=",$param_costcenter])]
    rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: $tags)
    rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: [join(["rs_backup:lineage=",$param_server_lineage])])

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

    task_label($server_ip_address)

    # MOUNT PREREQUISITE IMAGE DEVICE-SDB
    $restore_rdystest = {
        'DEBUGSCRIPT':"text:true",
        'LINEAGE':join(['text:', $param_rdsystest_image, ""]),
        'DRIVE_TYPE':"text:",
        'DRIVE_SIZE':"text:",
        'MOUNTPOINT':"text:/dr01"
    }

    # Call the server template script to create and mount the new mount point.
    call server_templates_utilities.run_script_inputs(@linux_server, "QAD All - Create & Mount Linux Volume from Snapshot" , $restore_rdsystest)

    task_label("Creating and mounting /dr01 filesystem")

    # MOUNT QAD CACHE AREA DEVICE-SDC
    $restore_qadcache = {
        'DEBUGSCRIPT':"text:true",
        'LINEAGE':"text:gcp-qad-sbox-009-rs-cache",
        'DRIVE_TYPE':"text:",
        'DRIVE_SIZE':"text:",
        'MOUNTPOINT':"text:/qad"
    }

    # Call the server template script to create and mount the new mount point.
    call server_templates_utilities.run_script_inputs(@linux_server, "QAD All - Create & Mount Linux Volume from Snapshot" , $restore_qadcache)

    task_label("Creating and mounting /qad filesystem")

    # create log entry
    rs_cm.audit_entries.create(audit_entry: {auditee_href: @@deployment.href, summary: "QAD All - Add QAD Special Linux Groups/Accounts"})
    $createaccinp = {
       'DEBUGSCRIPT':"text:true"
    }

    # Now run the set admin script which will use the newly updated credential
    call server_templates_utilities.run_script_inputs(@linux_server, "QAD All - Add QAD Special Linux Groups/Accounts" , $createaccinp )

    task_label("Creating QAD Special Linux Groups/Accounts")

    # Call the server template script to create and mount the SWAP volume.
    call server_templates_utilities.run_script_no_inputs(@linux_server, "QAD All - Create & Enable Linux Swap Volume")

    task_label("Creating and mounting Linux Swap Volume")

end

# post launch action to create snapshot/backup
define take_snapshot(@linux_server, $param_server_lineage) do

  task_label("Create snapshot of attached disk /dr01")

  call account_utilities.getUserLogin() retrieve $userlogin

  # create log entry
  rs_cm.audit_entries.create(audit_entry: {auditee_href: @@deployment.href, summary: join(["Create Snapshot of attached disk, ", $param_server_lineage, $param_mount_point])})
  $takessinp = {
    'BACKUP_NAME':"text:",
    'DEBUGSCRIPT':"text:true",
    'DESCRIPTION':"text:",
    'LINEAGE':join(['text:',$userlogin,"-",$param_server_lineage, ""]),
    'MOUNTPOINT':"text:/dr01"
  }

  # Now run the set admin script which will use the newly updated credential
  call server_templates_utilities.run_script_inputs(@linux_server, "QAD All - Take Linux Volume Snapshot", $takessinp )

end

# post launch action to create QAD Product Local Accounts & Groups
#define create_qad_local_accounts(@linux_server) do
#
#  task_label("Create QAD Local Users/Groups")
#
  # create log entry
# rs_cm.audit_entries.create(audit_entry: {auditee_href: @@deployment.href, summary: "QAD All - Add QAD Special Linux Groups/Accounts"})
# $createaccinp = {
#   'DEBUGSCRIPT':"text:true"
# }
#
  # Now run the set admin script which will use the newly updated credential
# call server_templates_utilities.run_script_inputs(@linux_server, "QAD All - Add QAD Special Linux Groups/Accounts" , $createaccinp )
#
#end
