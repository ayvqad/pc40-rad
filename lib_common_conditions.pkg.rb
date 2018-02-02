name "LIB - Common conditions"
rs_ca_ver 20160622
short_description "Conditions that are commonly used across multiple CATs"

package "pft/conditions"
import "pft/parameters"
import "pft/mappings"

mapping "map_cloud" do
  like $mappings.map_cloud
end

condition "needsSshKey" do
  equals?(map("map_cloud", $param_location, "ssh_key"), "@ssh_key")
end

condition "needsSecurityGroup" do
  equals?(map("map_cloud", $param_location, "sg"), "@sec_group")
end

condition "needsPlacementGroup" do
  equals?(map("map_cloud", $param_location, "pg"), "@placement_group")
end

condition "invSphere" do
  equals?($param_location, "VMware")
end

condition "inAzure" do
  equals?($param_location, "Azure")
end

## needed for compilation
parameter "param_location" do
  like $parameters.param_location
end
