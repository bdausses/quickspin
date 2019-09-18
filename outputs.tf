# # Outputs

# Chef Server
output "chef_server_url" {
  value            = module.base_mod.chef_server_url
}

output "a2_server_url" {
  value            = module.base_mod.a2_server_url
}

output "bldr_server_url" {
  value            = module.base_mod.bldr_server_url
}
#
# # Automate Server
# output "automate_server_url" {
#   value            = "https://${lookup(local.common_tags, "X-Contact")}-${lookup(local.common_tags, "X-Project")}-automate.${data.aws_route53_zone.selected.name}"
# }
#
# # Automate Server
# output "bldr_server_url" {
#   value            = "https://${lookup(local.common_tags, "X-Contact")}-${lookup(local.common_tags, "X-Project")}-bldr.${data.aws_route53_zone.selected.name}"
# }
#
# # output "credentials" {
# #   sensitive        = true
# #   value            = "${data.template_file.chef-server-creds.rendered}"
# # }
# # output "fqdn" {
# #   value            = "${aws_instance.chef-server.tags.Name}"
# # }
# # output "knife_rb" {
# #   value            = ".chef/knife.rb"
# # }
# # output "organization" {
# #   value            = "${var.chef_org["short"]}"
# # }
# # output "password" {
# #   sensitive        = true
# #   value            = "${base64sha256(aws_instance.chef-server.id)}"
# # }
# # output "private_ip" {
# #   value            = "${aws_instance.chef-server.private_ip}"
# # }
# # output "public_ip" {
# #   value            = "${aws_instance.chef-server.public_ip}"
# # }
# # output "secret_file" {
# #   value            = ".chef/encrypted_data_bag_secret"
# # }
# # output "security_group_id" {
# #   value            = "${aws_security_group.chef-server.id}"
# # }
# # output "user_key" {
# #   value            = ".chef/${var.chef_user["username"]}.pem"
# # }
# # output "username" {
# #   value            = "${var.chef_user["username"]}"
# # }
