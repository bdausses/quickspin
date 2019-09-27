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
