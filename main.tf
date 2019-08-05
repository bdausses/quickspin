provider "aws" {
  region     = "${var.region}"
}

module "base_mod" {
  source                    = "./modules/base"
  common_tags               = "${local.common_tags}"
  a2_license                = "${var.a2_license}"
  a2_admin_password         = "${var.a2_admin_password}"
  key_name                  = "${var.key_name}"
  instance_key              = "${var.instance_key}"
  bldr_server_instance_type = "${var.bldr_server_instance_type}"
  chef_server_instance_type = "${var.chef_server_instance_type}"
  a2_server_instance_type   = "${var.a2_server_instance_type}"
  chef_user                 = "${local.chef_user}"
  harvest_and_update_knife  = "${var.harvest_and_update_knife}"
  chef_server_zone_id       = "${var.chef_server_zone_id}"
  a2_server_zone_id         = "${var.a2_server_zone_id}"
}

module "centos_sample_nodes" {
  source                = "./modules/centos_sample_nodes"
  common_tags           = "${local.common_tags}"
  key_name              = "${var.key_name}"
  instance_key          = "${var.instance_key}"
  node_count            = "${var.centos_sample_node_count}"
  chef_server_zone_id   = "${var.chef_server_zone_id}"
}

module "rhel_sample_nodes" {
  source                = "./modules/rhel_sample_nodes"
  common_tags           = "${local.common_tags}"
  key_name              = "${var.key_name}"
  instance_key          = "${var.instance_key}"
  node_count            = "${var.rhel_sample_node_count}"
  chef_server_zone_id   = "${var.chef_server_zone_id}"
}

module "sles_sample_nodes" {
  source                = "./modules/sles_sample_nodes"
  common_tags           = "${local.common_tags}"
  key_name              = "${var.key_name}"
  instance_key          = "${var.instance_key}"
  node_count            = "${var.sles_sample_node_count}"
  chef_server_zone_id   = "${var.chef_server_zone_id}"
}

module "ubuntu_sample_nodes" {
  source                = "./modules/ubuntu_sample_nodes"
  common_tags           = "${local.common_tags}"
  key_name              = "${var.key_name}"
  instance_key          = "${var.instance_key}"
  node_count            = "${var.ubuntu_sample_node_count}"
  chef_server_zone_id   = "${var.chef_server_zone_id}"
}
