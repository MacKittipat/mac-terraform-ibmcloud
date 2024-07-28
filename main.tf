variable "ibmcloud_api_key" {}

provider "ibm" {
  region = "jp-tok"
  ibmcloud_api_key = var.ibmcloud_api_key
}

resource "ibm_is_vpc" "mac-vpc" {
  name = "mac-pvc"
}