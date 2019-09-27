# Quickspin
This repo contains terraform code that will quickly:
- Spin up a Chef server
- Spin up a Chef Automate server
- Set up reporting from the Chef server into Automate
- Spin up an On-Prem Builder server and set up OAUTH with the Automate instance (OPTIONAL)
- Spin up sample nodes to manage (OPTIONAL)

**DISCLAIMER**:  This code was originally intended to quickly spin up a demo environment.  There are most certainly optimizations that can and should be made if you were going to use this to spin up a stack for actual usage.

*Translation*:  YMMV, and do your due dilligence if you are going to use this for anything other than a transient demo environment.

## Modules
### Base
This module is responsible for spinning up the Chef server, the Chef Automate server, the On-Prem Builder server, and them taking care of all the plumbing to connect everything up.  These servers are built with the latest available CentOS AMIs, and are provisioned with the latest versions of the various Chef products.

**NOTE**:  There is functionality here that will automatically harvest the newly created user's key from the Chef server, and update a `~/.chef/knife-override.rb` file.  The intent here is to make the newly created stack immediately accessible via knife when the plan is completed.  This functionality requires `gsed` in your path (installed via `brew install gnu-sed`), a keys directory should be located at `~/.chef/keys`, and it also requires your knife.rb to be located at `~/.chef/knife.rb`.  Inside that file, you need to have the following block:

```
# Allow overriding values in this knife.rb
require 'chef/config'
knife_override = "#{home_dir}/.chef/knife-override.rb"
Chef::Config.from_file(knife_override) if File.exist?(knife_override)
```

If you want to use this:
- make sure your knife.rb file and knife-override.rb file are located at `~/.chef`
- create a keys directory at `~/.chef/keys` or override that path by setting a value for `local_keys_directory` in your terraform.tfvars
- set `harvest_key = true` and `update_knife_override = true` in your tfvars file.

An example `knife-override.rb` is also included in this repo.

Ping me if you don't understand this or want to dig deeper here.

### Centos Sample Nodes
This module controls spinning up CentOS sample nodes.  It uses the latest available CentOS 7 image.  Control wether or not these nodes spin up by using an integer value for the variable `centos_sample_node_count`.

### RHEL Sample Nodes
This module controls spinning up RHEL sample nodes.  It uses the latest available RHEL 7 image.  Control wether or not these nodes spin up by using an integer value for the variable `rhel_sample_node_count`.

### SLES Sample Nodes
This module controls spinning up SLES sample nodes.  It uses the latest available SLES 7 image.  Control wether or not these nodes spin up by using an integer value for the variable `sles_sample_node_count`.

### Ubuntu Sample Nodes
This module controls spinning up Ubuntu sample nodes.  It uses the latest available Ubuntu 18.04 LTS image.  Control wether or not these nodes spin up by using an integer value for the variable `ubuntu_sample_node_count`.

## Usage
- Copy terraform.tfvars.example to terraform.tfvars.
  - `cp terraform.tfvars.example terraform.tfvars`
- Edit terraform.tfvars and use whatever values you need.
  - `vi terraform.tfvars`
    - **Note**, this plan expects to create DNS entries w/ Route53.  You will need to make sure to put in valid values for the DNS zone IDs.  Adjust any other values accordingly.
- Initialize and apply the plan.
  - `terraform init`
  - `terraform apply`

## Credit
Some ideas, code, and inspiration taken from:
https://github.com/mengesb/tf_chef_server

## License
This is licensed under [the Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0).
