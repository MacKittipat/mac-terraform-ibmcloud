variable "ibmcloud_api_key" {}

data "ibm_resource_group" "mac-group" {
  name = "mac-group"
}

provider "ibm" {
  region = "jp-tok"
  ibmcloud_api_key = var.ibmcloud_api_key
}
resource "ibm_is_vpc" "mac-vpc" {
  name = "mac-vpc"
  resource_group = data.ibm_resource_group.mac-group.id
  default_security_group_name = "mac-security-group"
  default_network_acl_name = "mac-nacl"
  default_routing_table_name = "mac-routing-table"
}

resource "ibm_is_subnet" "mac-subnet-1" {
  name = "mac-subnet-1"
  vpc = ibm_is_vpc.mac-vpc.id
  zone = "jp-tok-1"
  ipv4_cidr_block = "10.244.0.0/24"
  network_acl = ibm_is_vpc.mac-vpc.default_network_acl
  resource_group = data.ibm_resource_group.mac-group.id
}

resource "ibm_is_security_group" "mac-vsi-security-group" {
  name = "mac-vsi-security-group"
  vpc  = ibm_is_vpc.mac-vpc.id
  resource_group = data.ibm_resource_group.mac-group.id
}

resource "ibm_is_security_group_rule" "allow_inbound" {
  group = ibm_is_security_group.mac-vsi-security-group.id
  direction      = "inbound"
  remote         = "0.0.0.0/0"
}

resource "ibm_is_security_group_rule" "allow_outbound" {
  group = ibm_is_security_group.mac-vsi-security-group.id
  direction      = "outbound"
  remote         = "0.0.0.0/0"
}

# data "ibm_is_ssh_key" "ssh_key_id" {
#    name = "mac-ssh-key"
# }

# data "ibm_is_image" "ubuntu" {
#    name = "ibm-ubuntu-24-04-minimal-amd64-3"
# }

# resource "ibm_is_instance" "mac-vsi" {
#   name              = "my-vsi"
#   image             = data.ibm_is_image.ubuntu.id
#   profile           = "bx2-2x8" 
#   vpc               = ibm_is_vpc.mac-vpc.id
#   zone              = "jp-tok-1"
#   keys = [data.ibm_is_ssh_key.ssh_key_id.id]
#   resource_group = data.ibm_resource_group.mac-group.id

#   primary_network_interface {
#     subnet         = ibm_is_subnet.mac-subnet-1.id
#     security_groups = [ibm_is_security_group.mac-vsi-security-group.id]
#     resource_group = data.ibm_resource_group.mac-group.id
#   }
# }