#Copyright 2015 RightScale
#x
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.


#RightScale Cloud Application Template (CAT)

# DESCRIPTION
# Deploys a Windows Server of the type chosen by the user.
# It automatically imports the ServerTemplate it needs.
# Also, if needed by the target cloud, the security group and/or ssh key is automatically created by the CAT.
# FIXED VARIABLES USED FOR THIS CAT
#
#
# NETWORK SECURITY GROUP RULES
# from lib_common_resources
# sec_group_rule_qadui (22000-22100)
# sec_group_rule_qadtomcat (8080)
# sec_group_rule_qadqxtend (8090)
#
# SEE BELOW FOR DEFINITIONS RELATED TO
# - USER INPUTS, USER OUTPUTS
# - OPERATIONS (Standard Start, Stop, Enable, Pre-Start, Pre-Terminate)
# - Custom OPERATIONS (take_snapshot)
#
# KNOWN DEFECT(S)
# DCOPM-336 resource windows_server -> server_template_href find(map($map_st, "windows_server", "name"), revision: map($map_st, "windows_server", "rev")) returns conflicting resource types
#   Mitigation/Workaround -- Please update server_template href with the correct href for the version of the server_template you intend to use.
#
# CHANGE LOG
# DCOPM-299 Create CAT for Windows Server 2016 EE 2017 Prerequisites (Publish)
# DCOPM-364 Rename 2017 prerequisite images based on new naming conventions
# AYV- Instance type changed to SMALL/MEDIUM/LARGE
# IZH - DCOPM-362 - change mapping "map_st" from rev 7 to rev 9
name 'Deployment Certification 2017'
rs_ca_ver 20160622
short_description "![logo](https://s3.amazonaws.com/rs-pft/cat-logos/windows.png)

Get a Windows Server VM for QAD ERP Deployment Certification in any of our supported public or private clouds"
long_description "Allows you to select different windows server types and cloud and performance level you want.\n
\n
Clouds Supported: <B>Google, VMWare</B>"

import "pft/parameters"
import "pft/mappings"
import "pft/resources", as: "common_resources"
import "pft/conditions"
import "pft/server_templates_utilities"
import "pft/cloud_utilities"
import "pft/account_utilities"

##################
# User inputs    #
##################

parameter "param_location" do

  category "Deployment Options"
  label "Cloud"
  type "string"
  allowed_values "Google US-West"
  default "Google US-West"

end

parameter "param_servertype" do

  category "Deployment Options"
  label "Select Environment to Deploy from this list"
  type "list"
  allowed_values "rl10-2017-windows-2016-prereqs-oe1171-java18", "rl10-2017-windows-2016-prereqs-oe1163-java18"
  default "rl10-2017-windows-2016-prereqs-oe1171-java18"

end

parameter "param_instancetype" do

  like $parameters.param_instancetype
  #allowed_values "SMALL", "MEDIUM", "LARGE", "HUGH"
  allowed_values "MEDIUM"
  default "MEDIUM"

end

parameter "param_username" do

  category "User Inputs"
  label "Windows Username"
  # description "Username (will be created)."
  type "string"
  no_echo "false"

end

parameter "param_password" do

  category "User Inputs"
  label "Windows Password"
  description "Minimum at least 8 characters and must contain at least one of each of the following:
  Uppercase characters, Lowercase characters, Digits 0-9, Non alphanumeric characters [@#\$%^&+=]."
  type "string"
  min_length 8
  max_length 32
  # This enforces a stricter windows password complexity in that all 4 elements are required as opposed to just 3.
  allowed_pattern '(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&+=])'
  no_echo "true"

end

parameter "param_costcenter" do

  category "User Inputs"
  like $parameters.param_costcenter

end


################################
# Outputs returned to the user #
################################
output "rdp_link" do

  label "RDP Link"
  category "Output"
  description "RDP Link to the Windows server."

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

  "windows_server" => {
    "name" => "QAD All Pre-Requisites Windows Server",
    "rev" => "9",
  },
}

end

mapping "map_mci" do {

    "rl10-2017-windows-2016-prereqs-oe1171-java18" => {
    "mci" => "mci_rl10_Windows2016_prerequisites--oe117-java18",
    "mci_rev" => "1"
    },
    "rl10-2017-windows-2016-prereqs-oe1163-java18" => {
    "mci" => "mci_rl10_Windows2016_prerequisites--oe1163-java18",
    "mci_rev" => "1"
    },
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
resource "windows_server", type: "server" do

  name 'Windows Server'
  cloud map($map_cloud, $param_location, "cloud")
  datacenter map($map_cloud, $param_location, "zone")
  server_template_href find(map($map_st, "windows_server", "name"), revision: map($map_st, "windows_server", "rev"))
  # server_template_href '/api/server_templates/401761003'
  multi_cloud_image find(map($map_mci, $param_servertype, "mci"))
  # multi_cloud_image_href '/api/multi_cloud_images/433821003'
  instance_type map($map_instancetype, $param_instancetype, $param_location)
  ssh_key_href map($map_cloud, $param_location, "ssh_key")
  security_group_hrefs map($map_cloud, $param_location, "sg")
  placement_group_href map($map_cloud, $param_location, "pg")

  inputs do {
    "ADMIN_ACCOUNT_NAME" => join(["text:",$param_username]),
    "ADMIN_PASSWORD" => join(["cred:CAT_WINDOWS_ADMIN_PASSWORD-",@@deployment.href]), # this credential gets created below using the user-provided password.
    "FIREWALL_OPEN_PORTS_TCP" => "text:3389",
    "SYS_WINDOWS_TZINFO" => "text:Pacific Standard Time",
  } end

end

### Security Group Definitions ###
# Note: Even though not all environments need or use security groups, the launch operation/definition will decide whether or not
# to provision the security group and rules.
resource "sec_group", type: "security_group" do

  condition $needsSecurityGroup
  like @common_resources.sec_group

end

resource "sec_group_rule_rdp", type: "security_group_rule" do

  condition $needsSecurityGroup
  like @common_resources.sec_group_rule_rdp

end

resource "sec_group_rule_qadui", type: "security_group_rule" do

    like @common_resources.sec_group_rule_qadui

end

resource "sec_group_rule_qadtomcat", type: "security_group_rule" do

    like @common_resources.sec_group_rule_qadtomcat

end


resource "sec_group_rule_qadqxtend", type: "security_group_rule" do

    like @common_resources.sec_group_rule_qadqxtend

end

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
     $rdp_link => $server_ip_address,
   } end

end

operation "stop" do

  description "Stop and delete the VM instance; keep the persistent disks and data for next use"
  definition "stop"

end

operation "start" do

  description "Create the VM instance from the existing disks and data"
  definition "start"

  output_mappings do {
     $rdp_link => $server_ip_address,
   } end

end

operation "terminate" do

  description "Delete the VM instance and destroy all associated resources (disks, networks, settings)"
  definition "pre_auto_terminate"

end

operation "update_server_password" do

  label "Update Administrator Password"
  description "Update/reset the Administrator password."
  definition "update_password"

end


##########################
# DEFINITIONS (i.e. RCL) #
##########################

# Define the "stop" behavior
define stop(@windows_server) return @windows_server do

  # Issue the stop, which deletes the instance, without deleting the persistent disks
  @windows_server.current_instance().stop()

end

# Define the "start" behavior - return the new server IP address link
define start(@windows_server) return @windows_server, $server_ip_address do

  # Create the VM instance from the current windows_server deployment
  @windows_server.current_instance().start()

  # Retrieve the server IP address
  call account_utilities.find_shard() retrieve $shard_number
  call account_utilities.find_account_number() retrieve $account_number
  call account_utilities.get_server_access_link(@windows_server, "RDP", $shard_number, $account_number) retrieve $server_ip_address

end

# Import and set up what is needed for the server and then launch it.
define pre_auto_launch($map_cloud, $param_location, $param_password, $map_st) do

  # Need the cloud name later on
  $cloud_name = map( $map_cloud, $param_location, "cloud" )

  # Check if the selected cloud is supported in this account.
  # Since different PIB scenarios include different clouds, this check is needed.
  # It raises an error if not which stops execution at that point.
  call cloud_utilities.checkCloudSupport($cloud_name, $param_location)

  # Find and import the server template - just in case it hasn't been imported to the account already
  call server_templates_utilities.importServerTemplate($map_st)

  # Create the Admin Password credential used for the server based on the user-entered password.
  $credname = join(["CAT_WINDOWS_ADMIN_PASSWORD-",@@deployment.href])
  rs_cm.credentials.create({"name":$credname, "value": $param_password})

end

define enable(@windows_server, $param_costcenter) return $server_ip_address do

  # Tag the servers with the selected project cost center ID.
  $tags=[join(["costcenter:id=",$param_costcenter])]
  rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: $tags)

  # Retrieve the server IP address
  call account_utilities.find_shard() retrieve $shard_number
  call account_utilities.find_account_number() retrieve $account_number
  call account_utilities.get_server_access_link(@windows_server, "RDP", $shard_number, $account_number) retrieve $server_ip_address

end

# post launch action to change the credentials
define update_password(@windows_server, $param_password) do
  task_label("Update the windows server password.")

  if $param_password
    $cred_name = join(["CAT_WINDOWS_ADMIN_PASSWORD-",@@deployment.href])
    # update the credential
    rs_cm.audit_entries.create(audit_entry: {auditee_href: @@deployment.href, summary: join(["Updating credential, ", $cred_name])})
    @cred = rs_cm.credentials.get(filter: [ join(["name==",$cred_name]) ])
    @cred.update(credential: {"value" : $param_password})
  end

  # Now run the set admin script which will use the newly updated credential.
  call server_templates_utilities.run_script_no_inputs(@windows_server, "SYS Set admin account (v13.5.0-LTS)")

end

# Delete the credential created for the windows password
define pre_auto_terminate() do

  # Delete the cred we created for the user-provided password
  $credname = join(["CAT_WINDOWS_ADMIN_PASSWORD-",@@deployment.href])
  @cred=rs_cm.credentials.get(filter: [join(["name==",$credname])])
  @cred.destroy()

end
