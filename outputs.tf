# # Outputs

# Chef Server
output "chef_server_url" {
  value            = module.base_mod.chef_server_url
}

# Automate Server
output "a2_server_url" {
  value            = module.base_mod.a2_server_url
}

# Bldr Server
output "bldr_server_fqdn" {
  value            = module.base_mod.bldr_server_fqdn
}

# Centos Sample nodes
output "centos_sample_nodes" {
  value            = module.centos_sample_nodes.centos_sample_nodes
}

# RHEL Sample nodes
output "rhel_sample_nodes" {
  value            = module.rhel_sample_nodes.rhel_sample_nodes
}

# SLES Sample nodes
output "sles_sample_nodes" {
  value            = module.sles_sample_nodes.sles_sample_nodes
}

# Centos Sample nodes
output "ubuntu_sample_nodes" {
  value            = module.ubuntu_sample_nodes.ubuntu_sample_nodes
}
