output "ubuntu_sample_nodes" {
  value = aws_route53_record.ubuntu_sample_node.*.fqdn
}
