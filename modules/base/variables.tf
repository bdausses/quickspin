# Key Name - The name of your key at AWS.
variable "key_name" {}

# Instance Key - The local copy of your key file.
variable "instance_key" {}

# Common Tags map gets passed in from the root module.
variable "common_tags" { type = "map" }

# Chef User
variable "chef_user" {
  type             = "map"
  description      = "Chef User"
}

# Chef Org
variable "chef_org" {
  type             = "map"
  description      = "Chef Organization"
  default          = {
    long_name      = "Chef Demo"
    short_name     = "chef-demo"
  }
}

# A2 License gets passed in from the root module.
variable "a2_license" {}

# A2 Admin Password gets passed in from the root module.
variable "a2_admin_password" {}

# Instances types get passed in from root module.
variable "bldr_server_instance_type" {}
variable "chef_server_instance_type" {}
variable "a2_server_instance_type" {}

# This determines if the .pem key gets harvested and if the local
# knife-override.rb file gets updated.
variable "harvest_and_update_knife" {}

# Chef Server DNS info
# You can get this information by looking in Route53 -> Hosted Zones -> Hosted Zone ID (on right hand side of GUI)
variable "chef_server_zone_id" {}

# A2 Server DNS info
# You can get this information by looking in Route53 -> Hosted Zones -> Hosted Zone ID (on right hand side of GUI)
variable "a2_server_zone_id" {}

# Bldr Server
variable "provision_bldr" {}
