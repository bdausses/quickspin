# This module is responsible for setting up any sample nodes running RHEL.

# Find the most recent RHEL 7 AMI
data "aws_ami" "rhel" {
    most_recent = true
    owners = ["309956199498"]
    filter {
        name   = "name"
        values = ["RHEL-7.?*GA*"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}


# Spin up the sample node
resource "aws_instance" "rhel_sample_node" {
  ami           = "${data.aws_ami.rhel.id}"
  count         = "${var.node_count}"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"
  security_groups = ["${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-allow-all"]
  tags = "${merge(
  var.common_tags,
  map(
    "Name", "${lookup(var.common_tags, "X-Contact")}_${lookup(var.common_tags, "X-Project")}_rhel_sample_node_${count.index + 1}",
    "X-Role", "RHEL 7 Sample Node ${count.index + 1}"
    )
  )}"
}

# RHEL sample nodes DNS entry
resource "aws_route53_record" "rhel_sample_node" {
  zone_id = "${var.chef_server_zone_id}"
  count   = "${var.node_count}"
  name    = "${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-rhel-sample-${count.index + 1}"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.rhel_sample_node[count.index].public_ip}"]
}
