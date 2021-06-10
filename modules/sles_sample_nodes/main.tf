# This module is responsible for setting up any sample nodes running SLES 12.

# Find the most recent SLES 12 AMI
data "aws_ami" "sles" {
    most_recent = true
    owners = ["013907871322"]
    filter {
        name   = "name"
        values = ["suse-sles-12-sp4-v*-hvm-ssd-x86_64"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}


# Spin up the sample node
resource "aws_instance" "sles_sample_node" {
  ami           = "${data.aws_ami.sles.id}"
  count         = "${var.node_count}"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"
  security_groups = [aws_security_group.allow-all.id]
  tags = "${merge(
  var.common_tags,
  map(
    "Name", "${lookup(var.common_tags, "X-Contact")}_${lookup(var.common_tags, "X-Project")}_sles_sample_node_${count.index + 1}",
    "X-Role", "SLES 12 Sample Node ${count.index + 1}"
    )
  )}"
  monitoring = true
  ebs_optimized = true
}

# SLES sample nodes DNS entry
resource "aws_route53_record" "sles_sample_node" {
  zone_id = "${var.domain_zone_id}"
  count   = "${var.node_count}"
  name    = "${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-sles-sample-${count.index + 1}"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.sles_sample_node[count.index].public_ip}"]
}
