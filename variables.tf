###############
# AWS variables
###############
# Region
variable "region" {
  default = "us-east-2" # Ohio
}

variable "aws_profile" {
  default="default"
  description = "aws_profile is the profile from your credentials file which we will use to authenticate to the AWS API."
}

variable "aws_credentials_file" {
  default="~/.aws/credentials"
  description = "aws_credentials_file is the file on your local disk from which we will obtain your AWS API credentials."
}

variable "bldr_server_instance_type" {
  default = "c4.xlarge"
}

variable "chef_server_instance_type" {
  default = "m5.large"
}

variable "a2_server_instance_type" {
  default = "m5.large"
}

# Key Name - The name of your key at AWS.
variable "key_name" {}

# Instance Key - The local copy of your key file.
variable "instance_key" {
  default = "~/.ssh/id_rsa"
}

# Define Common Tags and put them in a map
variable "tag_application" {}
variable "tag_contact" {}
variable "tag_customer" {}
variable "tag_dept" {}
variable "tag_production" {}
variable "tag_project" {}
variable "tag_sleep" {}
variable "tag_ttl" {}

locals {
  common_tags = "${map(
    "X-Application", "${var.tag_application}",
    "X-Contact", "${var.tag_contact}",
    "X-Customer", "${var.tag_customer}",
    "X-Dept", "${var.tag_dept}",
    "X-Production", "${var.tag_production}",
    "X-Project", "${var.tag_project}",
    "X-Sleep", "${var.tag_sleep}",
    "X-TTL", "${var.tag_ttl}",
  )}"
}

# DNS Domain Name
variable "domain" {
  default = "chef-demo.com"
}
#####################
# END - AWS variables
#####################

# Define Chef User variables and put them in a map
variable "email" {
  default = "chef_admin@example.com"
}
variable "first_name" {
  default = "Chef"
}
variable "last_name" {
  default = "Admin"
}
variable "username" {
  default = "chef_admin"
}

locals {
  chef_user = "${map(
    "email", "${var.email}",
    "first_name", "${var.first_name}",
    "last_name", "${var.last_name}",
    "username", "${var.username}",
  )}"
}

# Harvest created user's key file - Set this to true to auto harvest the key.
variable "harvest_key" {
  default = false
}

# Directory where the harvested key will be placed
variable "local_keys_directory" {
  default = "~/.chef/keys"
}

# Update the knife-override.rb file.  See README.md for explanation.
variable "update_knife_override" {
  default = false
}

# A2 License
# Note - Do not change this default value of "none" as that value is used to
#        determine wether or not to attempt to apply a license.  If you have a
#        valid license, put that in your tfvars file.
variable "a2_license" {
  default = "none"
}

# A2 Admin Password
variable "a2_admin_password" {
  default = "workstation!"
}

# Bldr Server - Set this to true if you would like to integrate a Bldr Server
variable "provision_bldr" {
  default = false
}

##############
# Sample nodes
##############
# Centos Sample nodes
variable "centos_sample_node_count" {
  default = 0
}

# RHEL Sample nodes
variable "rhel_sample_node_count" {
  default = 0
}

# SLES Sample nodes
variable "sles_sample_node_count" {
  default = 0
}

# Ubuntu Sample nodes
variable "ubuntu_sample_node_count" {
  default = 0
}
