# This module is responsible for setting up the Chef Server and the Chef
# Automate 2 server.  Additionally, it generates the necessary API key and
# configuration bits to get them talking to each other.

# Find the most recent CentOS 7 AMI
data "aws_ami" "centos" {
  most_recent = true

  filter {
    name   = "name"
    values = ["chef-highperf-centos7-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["446539779517"]
}

# Create Security Group
resource "aws_security_group" "allow-all" {
  name        = "${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-allow-all"
  description = "Allow all inbound/outbound traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

#############
# Chef Server
#############

# Chef server DNS entry
resource "aws_route53_record" "chef_server" {
  zone_id = "${var.domain_zone_id}"
  name    = "${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-chef"
  type    = "A"
  ttl     = "60"
  records = ["${aws_eip.chef_server_eip.public_ip}"]
}

# Chef server Elastic IP
resource "aws_eip" "chef_server_eip" {
  instance = "${aws_instance.chef_server.id}"
  depends_on = ["aws_instance.chef_server"]
  vpc      = true
}

# Set up Chef Server's dna.json
data "template_file" "dna_json" {
  template = "${file("${path.module}/files/dna.json.tpl")}"
  vars = {
    chef_server = "${aws_route53_record.chef_server.fqdn}"
    a2_server   = "${aws_route53_record.a2_server.fqdn}"
  }
}

# Spin up the Chef server
resource "aws_instance" "chef_server" {
  ami           = "${data.aws_ami.centos.id}"
  instance_type = "${var.chef_server_instance_type}"
  key_name      = "${var.key_name}"
  security_groups = ["${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-allow-all"]
  root_block_device {
    volume_size = "25"
    delete_on_termination = true
  }
  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${lookup(var.common_tags, "X-Contact")}_${lookup(var.common_tags, "X-Project")}_chef_server",
      "X-Role", "Chef Server"
      )
  )}"
  volume_tags = "${merge(
    var.common_tags,
    map(
      "Name", "${lookup(var.common_tags, "X-Contact")}_${lookup(var.common_tags, "X-Project")}_chef_server",
      "X-Role", "Chef Server"
      )
  )}"
}

# Post-provisioning steps for Chef server
resource "null_resource" "chef_preparation" {
  depends_on = ["aws_route53_record.chef_server", "aws_route53_record.a2_server"]
    triggers = {
        instance = "${aws_instance.chef_server.id}"
    }

    connection {
      host        ="${aws_eip.chef_server_eip.public_ip}"
      user           = "centos"
      private_key    = "${file("${var.instance_key}")}"
      }

    # Write .chef/dna.json for chef-solo run
    provisioner "file" {
      content        = "${data.template_file.dna_json.rendered}"
      destination    = "/tmp/dna.json"
    }

  # Install Chef Server
  provisioner "remote-exec" {
    inline = [
      "sudo yum install wget -y",
      "sudo mkdir /opt/chef-ssl && sudo chmod 755 /opt/chef-ssl",
      "cd /opt/chef-ssl",
      "sudo openssl req -x509 -newkey rsa:4096 -keyout chef_server.key -out chef_server.pem -nodes -days 365 -subj '/C=US/ST=WA/O=Chef Software/CN=${aws_route53_record.chef_server.fqdn}'",
      "sudo chmod 600 /opt/chef-ssl/chef_server.pem /opt/chef-ssl/chef_server.key",
      "curl -L https://www.chef.io/chef/install.sh | sudo bash",
      "sudo mkdir -p /var/chef/cache /var/chef/cookbooks",
      "sudo mkdir /opt/chef-keys && sudo chmod 700 /opt/chef-keys/",
      "wget -qO- https://supermarket.chef.io/cookbooks/chef-server/download | sudo tar xvzC /var/chef/cookbooks",
      "for dep in chef-ingredient; do wget -qO- https://supermarket.chef.io/cookbooks/$${dep}/download | sudo tar xvzC /var/chef/cookbooks; done",
      "sudo mkdir -p /etc/chef/accepted_licenses",
      "sudo touch /etc/chef/accepted_licenses/chef_infra_server",
      "sudo chef-solo -o 'recipe[chef-server::default]' -j /tmp/dna.json --chef-license accept"
    ]
  }

  # Set up Chef User and Org, and install Manage interface
  provisioner "remote-exec" {
    inline = [
      "sudo chef-server-ctl user-create ${var.chef_user["username"]} ${var.chef_user["first_name"]} ${var.chef_user["last_name"]} ${var.chef_user["email"]} ${base64sha256(self.id)} -f /opt/chef-keys/${var.chef_user["username"]}.pem",
      "sudo chmod 600 /opt/chef-keys/${var.chef_user["username"]}.pem",
      "sudo chef-server-ctl org-create ${var.chef_org["short_name"]} '${var.chef_org["long_name"]}' --association_user ${var.chef_user["username"]} --filename /opt/chef-keys/${var.chef_org["short_name"]}-validator.pem",
      "sudo chmod 600 /opt/chef-keys/${var.chef_org["short_name"]}-validator.pem",
      "sudo chef-server-ctl install chef-manage",
      "sudo chef-manage-ctl reconfigure --accept-license",
    ]
  }
}

# Deposit reporting token to Chef server, add reporting data and reconfigure
resource "null_resource" "deposit_reporting_token" {
  depends_on = [ "null_resource.harvest_reporting_token", "null_resource.chef_preparation" ]
  connection {
    host        ="${aws_eip.chef_server_eip.public_ip}"
    user           = "centos"
    private_key    = "${file("${var.instance_key}")}"
    }

    # Deposit reporting token
    provisioner "file" {
      source         = "/tmp/${aws_route53_record.a2_server.fqdn}_reporting_token.txt"
      destination    = "/tmp/${aws_route53_record.a2_server.fqdn}_reporting_token.txt"
    }

    # Remove that file from local storage
    provisioner "local-exec" {
      command = "rm /tmp/${aws_route53_record.a2_server.fqdn}_reporting_token.txt"
    }

    # Add data and reconfigure
    provisioner "remote-exec" {
      inline = [
        "sudo chef-server-ctl set-secret data_collector token \"`cat /tmp/${aws_route53_record.a2_server.fqdn}_reporting_token.txt`\"",
        "sudo chef-server-ctl restart nginx",
        "sudo chef-server-ctl restart opscode-erchef",
        "sudo chef-server-ctl reconfigure"
      ]
    }
  }

# Harvest user's key and update knife-override.rb
resource "null_resource" "harvest_key_and_update_knife_override" {
  #count = "${var.harvest_and_update_knife}"
  depends_on = [ "null_resource.deposit_reporting_token" ]
  connection {
    host        ="${aws_eip.chef_server_eip.public_ip}"
    user           = "centos"
    private_key    = "${file("${var.instance_key}")}"
    }

    # Harvest keys, update knife-override.rb, and fetch the Chef server's self signed SSL certificate
    provisioner "local-exec" {
      command = "rsync -a -e \"ssh -i ${var.instance_key} -o StrictHostKeyChecking=no\" --rsync-path=\"sudo rsync\" centos@${aws_eip.chef_server_eip.public_ip}:/opt/chef-keys/${var.chef_user["username"]}.pem ~/.chef/keys/${aws_route53_record.chef_server.fqdn}-${var.chef_user["username"]}.pem"
    }
    provisioner "local-exec" {
      command = "rsync -a -e \"ssh -i ${var.instance_key} -o StrictHostKeyChecking=no\" --rsync-path=\"sudo rsync\" centos@${aws_eip.chef_server_eip.public_ip}:/opt/chef-keys/${var.chef_org["short_name"]}-validator.pem ~/.chef/keys/${aws_route53_record.chef_server.fqdn}-${var.chef_org["short_name"]}-validator.pem"
    }
    provisioner "local-exec" {
      command = "gsed -i '/^chef_server_url/ d' ~/.chef/knife-override.rb"
    }
    provisioner "local-exec" {
      command = "gsed -i '/^client_key/ d' ~/.chef/knife-override.rb"
    }
    provisioner "local-exec" {
      command = "gsed -i '/^node_name/ d' ~/.chef/knife-override.rb"
    }
    provisioner "local-exec" {
      command = "echo \"chef_server_url \\\"https://${aws_route53_record.chef_server.fqdn}/organizations/${var.chef_org["short_name"]}\\\"\" | tee -a ~/.chef/knife-override.rb"
    }
    provisioner "local-exec" {
      command = "echo \"client_key \\\"~/.chef/keys/${aws_route53_record.chef_server.fqdn}-${var.chef_user["username"]}.pem\\\"\" | tee -a ~/.chef/knife-override.rb"
    }
    provisioner "local-exec" {
      command = "echo \"node_name \\\"${var.chef_user["username"]}\\\"\" | tee -a ~/.chef/knife-override.rb"
    }
    provisioner "local-exec" {
      command = "knife ssl fetch"
    }
    provisioner "local-exec" {
      command = "knife cookbook upload --include-dependencies chef-client omni_audit"
    }
}

###################
# End - Chef Server
###################

###########
# A2 Server
###########

# A2 server DNS entry
resource "aws_route53_record" "a2_server" {
  zone_id = "${var.domain_zone_id}"
  name    = "${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-automate"
  type    = "A"
  ttl     = "60"
  records = ["${aws_eip.a2_server_eip.public_ip}"]
}

# A2 server Elastic IP
resource "aws_eip" "a2_server_eip" {
  instance = "${aws_instance.a2_server.id}"
  depends_on = ["aws_instance.a2_server"]
  vpc      = true
}

# Set up A2 license file
data "template_file" "a2_license" {
  template = "${file("${path.module}/files/a2_license.tpl")}"
  vars = {
    content = "${var.a2_license}"
  }
}

# Set up patch file for Bldr integration
data "template_file" "enable_bldr_toml" {
  template = "${file("${path.module}/files/enable_bldr.toml.tpl")}"
  vars = {
    bldr_fqdn = "${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-bldr.chef-demo.com"
  }
}

# Spin up the A2 server
resource "aws_instance" "a2_server" {
    ami           = "${data.aws_ami.centos.id}"
    instance_type = "${var.a2_server_instance_type}"
    key_name      = "${var.key_name}"
    security_groups = ["${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-allow-all"]
    root_block_device {
      volume_size = "25"
      delete_on_termination = true
    }
    tags = "${merge(
      var.common_tags,
      map(
        "Name", "${lookup(var.common_tags, "X-Contact")}_${lookup(var.common_tags, "X-Project")}_a2_server",
        "X-Role", "Chef Server"
      )
    )}"
    volume_tags = "${merge(
      var.common_tags,
      map(
        "Name", "${lookup(var.common_tags, "X-Contact")}_${lookup(var.common_tags, "X-Project")}_a2_server",
        "X-Role", "Chef Server"
      )
    )}"
  }

# Post-provisioning steps for A2 server
resource "null_resource" "a2_preparation" {
  depends_on = ["aws_route53_record.a2_server"]
    triggers = {
        instance = "${aws_instance.a2_server.id}"
    }

    connection {
      host        ="${aws_eip.a2_server_eip.public_ip}"
      user           = "centos"
      private_key    = "${file("${var.instance_key}")}"
      }

    # Write /tmp/a2_license
    provisioner "file" {
      content     = "${data.template_file.a2_license.rendered}"
      destination = "/tmp/a2_license"
    }

    # Write /tmp/a2_license_apply for conditional license application
    provisioner "file" {
      source      = "${path.module}/files/a2_license_apply.sh"
      destination = "/tmp/a2_license_apply.sh"
    }

    # Write /tmp/download_compliance_profiles.sh
    provisioner "file" {
      source      = "${path.module}/files/download_compliance_profiles.sh"
      destination = "/tmp/download_compliance_profiles.sh"
    }

    # Write enable_bldr.toml so that bldr integration can work.
    provisioner "file" {
      content        = "${data.template_file.enable_bldr_toml.rendered}"
      destination    = "/tmp/enable_bldr.toml"
    }

    # Install Automate 2
    provisioner "remote-exec" {
      inline = [
        "sudo yum install -y epel-release",
        "sudo yum install -y jq",
        "cd /tmp",
        "curl -s https://packages.chef.io/files/current/latest/chef-automate-cli/chef-automate_linux_amd64.zip | gunzip - > chef-automate && chmod +x chef-automate",
        "sudo ./chef-automate init-config --fqdn ${aws_route53_record.a2_server.fqdn}",
        "sudo /usr/sbin/sysctl -w vm.max_map_count=262144",
        "sudo /usr/sbin/sysctl -w vm.dirty_expire_centisecs=20000",
        "echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf",
        "echo 'vm.dirty_expire_centisecs=20000' | sudo tee -a /etc/sysctl.conf",
        "sudo ./chef-automate deploy config.toml --accept-terms-and-mlsa --skip-preflight",
        "bash /tmp/a2_license_apply.sh",
        "sudo rm /tmp/a2_license_apply.sh",
        "sudo rm /tmp/a2_license",
        "export TOK=`sudo chef-automate admin-token`",
        "curl -sk -H \"api-token: $TOK\" -H \"Content-Type: application/json\" -d '{\"description\":\"Reporting Token - ${aws_route53_record.chef_server.fqdn}\",\"active\":true}' https://${aws_route53_record.a2_server.fqdn}/api/v0/auth/tokens | jq -r .value > /tmp/reporting_token",
        "sudo chown centos /tmp/reporting_token",
        "sudo chmod 600 /tmp/reporting_token",
        "sudo chown centos /tmp/automate-credentials.toml",
        "sudo chmod 600 /tmp/automate-credentials.toml",
        "sudo chef-automate iam admin-access restore ${var.a2_admin_password}",
        "bash /tmp/download_compliance_profiles.sh",
        "sudo rm /tmp/download_compliance_profiles.sh",
        "sudo chef-automate config patch /tmp/enable_bldr.toml",
        "sudo rm /tmp/enable_bldr.toml"
      ]
    }
}

# Harvest files
resource "null_resource" "harvest_reporting_token" {
  depends_on = [ "null_resource.a2_preparation" ]

    connection {
      host        ="${aws_eip.a2_server_eip.public_ip}"
      user           = "centos"
      private_key    = "${file("${var.instance_key}")}"
      }

      # Copy back reporting token
      provisioner "local-exec" {
        command = "scp -o stricthostkeychecking=no -i ${var.instance_key} centos@${aws_eip.a2_server_eip.public_ip}:/tmp/reporting_token /tmp/${aws_route53_record.a2_server.fqdn}_reporting_token.txt"
      }

      # Remove harvested file and initial credentials file.
      provisioner "remote-exec" {
        inline = [
          "sudo rm /tmp/automate-credentials.toml",
          "sudo rm /tmp/reporting_token"
        ]
      }
}

#################
# End - A2 Server
#################

#############
# Bldr Server
#############

# Bldr server DNS entry
resource "aws_route53_record" "bldr_server" {
  count = var.provision_bldr ? 1 : 0
  zone_id = "${var.domain_zone_id}"
  name    = "${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-bldr"
  type    = "A"
  ttl     = "60"
  records = ["${aws_eip.bldr_server_eip[count.index].public_ip}"]
}

# Bldr server Elastic IP
resource "aws_eip" "bldr_server_eip" {
  count = var.provision_bldr ? 1 : 0
  instance = "${aws_instance.bldr_server[count.index].id}"
  depends_on = ["aws_instance.bldr_server"]
  vpc      = true
}

# Set up Bldr's bldr.env file
data "template_file" "bldr_env" {
  template = "${file("${path.module}/files/bldr.env.tpl")}"
  vars = {
    bldr_fqdn = "${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-bldr.chef-demo.com"
    a2_fqdn   = "${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-automate.chef-demo.com"
  }
}

# Set up Bldr's bldr.env file
data "template_file" "populate_bldr" {
  template = "${file("${path.module}/files/populate_bldr.sh.tpl")}"
  vars = {
    bldr_fqdn = "${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-bldr.chef-demo.com"
  }
}

# Spin up the Bldr server
resource "aws_instance" "bldr_server" {
  count = var.provision_bldr ? 1 : 0
  ami           = "${data.aws_ami.centos.id}"
  instance_type = "${var.bldr_server_instance_type}"
  key_name      = "${var.key_name}"
  security_groups = ["${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-allow-all"]
  root_block_device {
    volume_size = "50"
    delete_on_termination = true
  }
  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${lookup(var.common_tags, "X-Contact")}_${lookup(var.common_tags, "X-Project")}_bldr_server",
      "X-Role", "On-Prem Bldr Server"
      )
  )}"
  volume_tags = "${merge(
    var.common_tags,
    map(
      "Name", "${lookup(var.common_tags, "X-Contact")}_${lookup(var.common_tags, "X-Project")}_bldr_server",
      "X-Role", "On-Prem Bldr Server"
      )
  )}"
}

# Post-provisioning steps for Bldr server
resource "null_resource" "bldr_preparation" {
  count = var.provision_bldr ? 1 : 0
  depends_on = ["aws_route53_record.bldr_server", "aws_route53_record.a2_server"]
    triggers = {
        instance = "${aws_instance.bldr_server[count.index].id}"
    }

    connection {
      host        ="${aws_eip.bldr_server_eip[count.index].public_ip}"
      user           = "centos"
      private_key    = "${file("${var.instance_key}")}"
      }

    # Write bldr.env so that bldr can be installed
    provisioner "file" {
      content        = "${data.template_file.bldr_env.rendered}"
      destination    = "/tmp/bldr.env"
    }

    # Write bldr.env so that bldr can be installed
    provisioner "file" {
      content        = "${data.template_file.populate_bldr.rendered}"
      destination    = "/tmp/populate_bldr.sh"
    }

  # Install Bldr Server
  provisioner "remote-exec" {
    inline = [
      "sudo yum install wget git -y",
      "cd /opt",
      "sudo git clone https://github.com/habitat-sh/on-prem-builder.git",
      "cd on-prem-builder",
      "sudo mv /tmp/bldr.env /opt/on-prem-builder/bldr.env",
      "export HAB_LICENSE=accept",
      "echo y | sudo -E ./install.sh"
    ]
  }
}

resource "null_resource" "bldr_preparation_2" {
  count = var.provision_bldr ? 1 : 0
  depends_on = ["aws_route53_record.bldr_server",
                "null_resource.a2_preparation",
                "null_resource.bldr_preparation"]
    triggers = {
        instance = "${aws_instance.bldr_server[count.index].id}"
    }

    connection {
      host        ="${aws_eip.bldr_server_eip[count.index].public_ip}"
      user           = "centos"
      private_key    = "${file("${var.instance_key}")}"
      }

  # Harvest A2 SSL cert and restart Bldr
  provisioner "remote-exec" {
    inline = [
      "openssl s_client -showcerts -connect ${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-automate.chef-demo.com:443 </dev/null 2>/dev/null|openssl x509 -outform PEM | sudo tee -a $(hab pkg path core/cacerts)/ssl/cert.pem",
      "sudo systemctl restart hab-sup",
    ]
  }
}
#
# # Deposit reporting token to Chef server, add reporting data and reconfigure
# resource "null_resource" "deposit_reporting_token" {
#   depends_on = [ "null_resource.harvest_reporting_token", "null_resource.chef_preparation" ]
#   connection {
#     host        ="${aws_eip.chef_server_eip.public_ip}"
#     user           = "centos"
#     private_key    = "${file("${var.instance_key}")}"
#     }
#
#     # Deposit reporting token
#     provisioner "file" {
#       source         = "/tmp/${aws_route53_record.a2_server.fqdn}_reporting_token.txt"
#       destination    = "/tmp/${aws_route53_record.a2_server.fqdn}_reporting_token.txt"
#     }
#
#     # Remove that file from local storage
#     provisioner "local-exec" {
#       command = "rm /tmp/${aws_route53_record.a2_server.fqdn}_reporting_token.txt"
#     }
#
#     # Add data and reconfigure
#     provisioner "remote-exec" {
#       inline = [
#         "sudo chef-server-ctl set-secret data_collector token \"`cat /tmp/${aws_route53_record.a2_server.fqdn}_reporting_token.txt`\"",
#         "sudo chef-server-ctl restart nginx",
#         "sudo chef-server-ctl restart opscode-erchef",
#         "sudo chef-server-ctl reconfigure"
#       ]
#     }
#   }
#
# # Harvest user's key and update knife-override.rb
# resource "null_resource" "harvest_key_and_update_knife_override" {
#   count = "${var.harvest_and_update_knife}"
#   depends_on = [ "null_resource.deposit_reporting_token" ]
#   connection {
#     host        ="${aws_eip.chef_server_eip.public_ip}"
#     user           = "centos"
#     private_key    = "${file("${var.instance_key}")}"
#     }
#
#     # Harvest keys, update knife-override.rb, and fetch the Chef server's self signed SSL certificate
#     provisioner "local-exec" {
#       command = "rsync -a -e \"ssh -i ${var.instance_key} -o StrictHostKeyChecking=no\" --rsync-path=\"sudo rsync\" centos@${aws_eip.chef_server_eip.public_ip}:/opt/chef-keys/${var.chef_user["username"]}.pem ~/.chef/keys/${aws_route53_record.chef_server.fqdn}-${var.chef_user["username"]}.pem"
#     }
#     provisioner "local-exec" {
#       command = "rsync -a -e \"ssh -i ${var.instance_key} -o StrictHostKeyChecking=no\" --rsync-path=\"sudo rsync\" centos@${aws_eip.chef_server_eip.public_ip}:/opt/chef-keys/${var.chef_org["short_name"]}-validator.pem ~/.chef/keys/${aws_route53_record.chef_server.fqdn}-${var.chef_org["short_name"]}-validator.pem"
#     }
#     provisioner "local-exec" {
#       command = "gsed -i '/^chef_server_url/ d' ~/.chef/knife-override.rb"
#     }
#     provisioner "local-exec" {
#       command = "gsed -i '/^client_key/ d' ~/.chef/knife-override.rb"
#     }
#     provisioner "local-exec" {
#       command = "gsed -i '/^node_name/ d' ~/.chef/knife-override.rb"
#     }
#     provisioner "local-exec" {
#       command = "echo \"chef_server_url \\\"https://${aws_route53_record.chef_server.fqdn}/organizations/${var.chef_org["short_name"]}\\\"\" | tee -a ~/.chef/knife-override.rb"
#     }
#     provisioner "local-exec" {
#       command = "echo \"client_key \\\"~/.chef/keys/${aws_route53_record.chef_server.fqdn}-${var.chef_user["username"]}.pem\\\"\" | tee -a ~/.chef/knife-override.rb"
#     }
#     provisioner "local-exec" {
#       command = "echo \"node_name \\\"${var.chef_user["username"]}\\\"\" | tee -a ~/.chef/knife-override.rb"
#     }
#     provisioner "local-exec" {
#       command = "knife ssl fetch"
#     }
#     provisioner "local-exec" {
#       command = "knife cookbook upload --include-dependencies chef-client omni_audit"
#     }

# Grab cert:
# openssl s_client -showcerts -connect bdausses-test.automate-demo.com:443 </dev/null 2>/dev/null|openssl x509 -outform PEM > /tmp/mycertfile.pem


###################
# End - Bldr Server
###################


# List Outputs
#output "Chef Automate Host Name" {
#    value = "${aws_route53_record.a2_server.fqdn}"
#}

#output "Chef Server Host Name" {
#    value = "${aws_route53_record.chef_server.fqdn}"
#}
