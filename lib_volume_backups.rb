name "LIB - Volume Mappings"
rs_ca_ver 20160622
short_description "Volume Backup Mappings"

package "pft/volume_mappings"

parameter "volume_backups" do

  category "User Options"
  label "Select Available Volume"
  type "list"
  allowed_values "blank","rs104197-apache-2.4.27","ms1-recipe-x"
  default "blank"

end

mapping "map_backups" do {

  "blank" => {
      "Disk" => "/api/clouds/3762/volume_snapshots/CC2LI9L1G1PVH"},
  "rs104197-apache-2.4.27" => {
      "Disk" => "/api/clouds/3762/volume_snapshots/3B24U8OV561US"},
  "sm1-recipe-x" =>  {
      "Disk" => "/api/clouds/3762/volume_snapshots/3B24U8OV561US"},
  }

end
