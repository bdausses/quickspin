# This module is responsible for setting up any sample nodes running Ubuntu.

# Find the most recent Ubuntu 18.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Spin up the sample node
resource "aws_instance" "ubuntu_sample_node" {
  ami           = "${data.aws_ami.ubuntu.id}"
  count         = "${var.node_count}"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"
  security_groups = [aws_security_group.allow-all.id]
  tags = "${merge(
  var.common_tags,
  map(
    "Name", "${lookup(var.common_tags, "X-Contact")}_${lookup(var.common_tags, "X-Project")}_ubuntu_sample_node_${count.index + 1}",
    "X-Role", "Ubuntu Sample Node ${count.index + 1}"
    )
  )}"
  monitoring = true
  ebs_optimized = true
}

# Ubuntu sample nodes DNS entry
resource "aws_route53_record" "ubuntu_sample_node" {
  zone_id = "${var.domain_zone_id}"
  count   = "${var.node_count}"
  name    = "${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-ubuntu-sample-${count.index + 1}"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.ubuntu_sample_node[count.index].public_ip}"]
}
