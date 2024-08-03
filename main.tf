variable "ibmcloud_api_key" {}

data "ibm_resource_group" "group-mac" {
  name = "group-mac"
}

data "ibm_is_ssh_key" "ssh-key-mac" {
  name = "ssh-key-mac"
}

data "ibm_is_image" "image-ubuntu" {
  name = "ibm-ubuntu-24-04-minimal-amd64-3"
}

provider "ibm" {
  region           = "jp-tok"
  ibmcloud_api_key = var.ibmcloud_api_key
}
resource "ibm_is_vpc" "vpc-mac" {
  name                        = "vpc-mac"
  resource_group              = data.ibm_resource_group.group-mac.id
  default_security_group_name = "sg-mac"
  default_network_acl_name    = "nacl-mac"
  default_routing_table_name  = "routing-table-mac"
}

resource "ibm_is_subnet" "subnet-mac-1" {
  name            = "subnet-mac-1"
  vpc             = ibm_is_vpc.vpc-mac.id
  zone            = "jp-tok-1"
  ipv4_cidr_block = "10.244.0.0/24"
  network_acl     = ibm_is_vpc.vpc-mac.default_network_acl
  resource_group  = data.ibm_resource_group.group-mac.id
}

resource "ibm_is_subnet_reserved_ip" "rip-subnet-mac-1" {
  subnet = ibm_is_subnet.subnet-mac-1.id
  name   = "rip-subnet-mac-1"
}

resource "ibm_is_security_group" "sg-vsi-mac" {
  name           = "sg-vsi-mac"
  vpc            = ibm_is_vpc.vpc-mac.id
  resource_group = data.ibm_resource_group.group-mac.id
}

resource "ibm_is_security_group_rule" "sg-rule-allow_inbound" {
  group     = ibm_is_security_group.sg-vsi-mac.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_security_group_rule" "sg-rule-allow_outbound" {
  group     = ibm_is_security_group.sg-vsi-mac.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_instance" "vsi-mac" {
  name           = "vsi-mac"
  image          = data.ibm_is_image.image-ubuntu.id
  profile        = "bx2-2x8"
  vpc            = ibm_is_vpc.vpc-mac.id
  zone           = "jp-tok-1"
  keys           = [data.ibm_is_ssh_key.ssh-key-mac.id]
  resource_group = data.ibm_resource_group.group-mac.id

  primary_network_interface {
    name            = "eth0"
    subnet          = ibm_is_subnet.subnet-mac-1.id
    security_groups = [ibm_is_security_group.sg-vsi-mac.id]
  }
}

resource "ibm_is_floating_ip" "fip-vsi-mac" {
  name           = "fip-vsi-mac"
  target         = ibm_is_instance.vsi-mac.primary_network_interface[0].id
  resource_group = data.ibm_resource_group.group-mac.id
}

resource "ibm_database" "db-postgresql-mac" {
  name              = "db-postgresql-mac"
  plan              = "standard"
  location          = "jp-tok"
  service           = "databases-for-postgresql"
  service_endpoints = "public-and-private"
  resource_group_id = data.ibm_resource_group.group-mac.id
  adminpassword     = "password12345678"

  group {
    group_id = "member"

    memory {
      allocation_mb = 4096
    }

    disk {
      allocation_mb = 5120
    }

    cpu {
      allocation_count = 3
    }
  }

  users {
    name     = "user123"
    password = "password12345678"
    type     = "database"
  }
}

resource "ibm_is_virtual_endpoint_gateway" "vpe-db-postgresql-mac" {
  name = "vpe-db-postgresql-mac"
  vpc             = ibm_is_vpc.vpc-mac.id
  resource_group  = data.ibm_resource_group.group-mac.id
  security_groups = [ibm_is_security_group.sg-vsi-mac.id]
  target {
    crn           = ibm_database.db-postgresql-mac.id
    resource_type = "provider_cloud_service"
  }
}

resource "ibm_is_virtual_endpoint_gateway_ip" "rip_vpe-db-postgresql-mac" {
  gateway     = ibm_is_virtual_endpoint_gateway.vpe-db-postgresql-mac.id
  reserved_ip = ibm_is_subnet_reserved_ip.rip-subnet-mac-1.reserved_ip
}

# resource "ibm_resource_instance" "event-stream-mac" {
#   name              = "event-stream-mac"
#   service           = "messagehub"
#   plan              = "standard" # "lite", "enterprise-3nodes-2tb"
#   location          = "jp-tok"
#   resource_group_id = data.ibm_resource_group.group-mac.id
# }