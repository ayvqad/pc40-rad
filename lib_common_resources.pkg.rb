name "LIB - Common resources"
rs_ca_ver 20160622
short_description "Resources that are commonly used across CATs"

package "pft/resources"

import "pft/parameters"
import "pft/mappings"
import "pft/conditions"

### Security Group Definitions ###
# Note: Even though not all environments need or use security groups, the launch operation/definition will decide whether or not
# to provision the security group and rules.
#
#
# QAD IP Asset CI/DR
# 167.3.0.0/16
# Use this to allow only access from users on QAD network or VPN.
# /16 is the broadest subnet

resource "sec_group", type: "security_group" do

  name join(["SecGrp-",last(split(@@deployment.href,"/"))])
  description "Server security group."
  cloud map( $map_cloud, $param_location, "cloud" )

end

# Security Group Definition for SSH

resource "sec_group_rule_ssh", type: "security_group_rule" do

  name join(["SshRule-",last(split(@@deployment.href,"/"))])
  description "Allow SSH access."
  source_type "cidr_ips"
  security_group @sec_group
  protocol "tcp"
  direction "ingress"
  cidr_ips "167.3.0.0/16"
  protocol_details do {
    "start_port" => "22",
    "end_port" => "22"
  } end

end


# Security Group Definition for RDP

resource "sec_group_rule_rdp", type: "security_group_rule" do

  name join(["RdpRule-",last(split(@@deployment.href,"/"))])
  description "Allow RDP access."
  source_type "cidr_ips"
  security_group @sec_group
  protocol "tcp"
  direction "ingress"
  cidr_ips "167.3.0.0/16"
  protocol_details do {
    "start_port" => "3389",
    "end_port" => "3389"
  } end

end

# Security Group Definition for QAD .NetUI access

resource "sec_group_rule_qadui", type: "security_group_rule" do

  name join(["UIRule-",last(split(@@deployment.href,"/"))])
  description "Allow QAD UI access."
  source_type "cidr_ips"
  security_group @sec_group
  protocol "tcp"
  direction "ingress"
  cidr_ips "167.3.0.0/16"
  protocol_details do {
    "start_port" => "22000",
    "end_port" => "22100"
  } end

end

# Security Group Definition for QAD Tomcat

resource "sec_group_rule_qadtomcat", type: "security_group_rule" do

  name join(["TomcatRule-",last(split(@@deployment.href,"/"))])
  description "Allow Tomcat access."
  source_type "cidr_ips"
  security_group @sec_group
  protocol "tcp"
  direction "ingress"
  cidr_ips "167.3.0.0/16"
  protocol_details do {
    "start_port" => "8080",
    "end_port" => "8080"
  } end

end

# Security Group Definition for QAD QXtend Inbound / Outbound

resource "sec_group_rule_qadqxtend", type: "security_group_rule" do

  name join(["QxtendRule-",last(split(@@deployment.href,"/"))])
  description "Allow QXtend access."
  source_type "cidr_ips"
  security_group @sec_group
  protocol "tcp"
  direction "ingress"
  cidr_ips "167.3.0.0/16"
  protocol_details do {
    "start_port" => "8090",
    "end_port" => "8090"
  } end

end


### SSH key declarations ###
resource "ssh_key", type: "ssh_key" do

  name join(["sshkey_", last(split(@@deployment.href,"/"))])
  cloud map($map_cloud, $param_location, "cloud")

end

### Placement group declaration ###
resource "placement_group", type: "placement_group" do

  name last(split(@@deployment.href,"/"))
  cloud map($map_cloud, $param_location, "cloud")

end


## In order for this CAT to compile, the parameters passed to map()
## must exist. When this package is consumed, the consuming CAT will
## redefine these

mapping "map_cloud" do

  like $mappings.map_cloud

end

parameter "param_location" do

  like $parameters.param_location

end

condition "needsSshKey" do

  like $conditions.needsSshKey

end

condition "needsPlacementGroup" do

  like $conditions.needsPlacementGroup

end
