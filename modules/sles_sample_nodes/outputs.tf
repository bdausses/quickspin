output "sles_sample_nodes" {
  value = aws_route53_record.sles_sample_node.*.fqdn
}
