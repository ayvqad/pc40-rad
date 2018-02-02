name "LIB - Common parameters"
rs_ca_ver 20160622
short_description "Parameters that are commonly used across multiple CATs"

package "pft/parameters"

parameter "param_location" do
  category "Deployment Options"
  label "Cloud"
  type "string"
  allowed_values   "Google AU (Sydney)","Google CA (Montréal)","Google BE (St. Ghislain)","Google BR (São Paulo)","Google DE (Frankfurt)","Google GB (London) ","Google IN (Mumbai)","Google JP (Tokyo)","Google NL (Eemshaven)","Google SG (Jurong West)","Google TW (Changhua County)","Google US (Moncks Corner, SC)","Google US (Los Angeles, CA)","Google US (Ashburn, VA)","Google US (The Dalles, OR)",
    "Google US (Council Bluffs, IA)","Flexential US (Arapahoe, CO)", "SoftLayer FR (Paris)", "SoftLayer JP (Tokyo)", "SoftLayer SG (Singapore)", "SoftLayer AU (Sydney)", "SoftLayer NL (Amsterdam)","QAD US (Santa Barbara, CA)"
  default "Google US (The Dalles, OR)"
end

parameter "param_instancetype" do
  category "Deployment Options"
  label "Server Resource Profile (approximate)"
  type "list"
  allowed_values "SMALL",
    "MEDIUM", "LARGE", "HUGE"
  default "MEDIUM"
end

parameter "param_costcenter" do
  category "Deployment Options"
  label "Cost Center"
  type "string"
  allowed_values "4025 Operations", "4405 MFG Dev/Sup Chain", "4415 Foundation","4435 Release Plan & Mgt", "4455 RD Financials", "4475 RD Customer Mgt", "4485 RD Supply Chain", "4495 RD I19", "4515 RD Quality/Performance/Tools", "4525 RD Foundation Development", "4435 CEBOS", "4545 RD Translations", "4575 RD Content Development", "4585 RD Product Center", " 4615 RD Automation Solutions"
  default "4515 RD Quality/Performance/Tools"
end
