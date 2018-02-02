name "LIB - Cloud Utilities"
rs_ca_ver 20160622
short_description "RCL definitions for helping interact with clouds"

package "pft/cloud_utilities"

# Checks if the account supports the selected cloud
define checkCloudSupport($cloud_name, $param_location) do

  # Gather up the list of clouds supported in this account.
  @clouds = rs_cm.clouds.get()
  $supportedClouds = @clouds.name[] # an array of the names of the supported clouds

  # Check if the selected/mapped cloud is in the list and yell if not
  if logic_not(contains?($supportedClouds, [$cloud_name]))

    raise "Your account does not support the "+$param_location+" cloud. Try deploying to a different cloud, or contact QAD IT for more information on how to enable access."

  end

end
