output "rhel_sample_nodes" {
  value = aws_route53_record.rhel_sample_node.*.fqdn
}
