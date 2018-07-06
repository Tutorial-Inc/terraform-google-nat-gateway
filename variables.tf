/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable module_enabled {
  description = "To disable this module, set this to false"
  default     = true
}

variable project {
  description = "The project to deploy to, if not set the default provider project is used."
  default     = ""
}

variable network {
  description = "The network to deploy to"
  default     = "default"
}

variable network_project {
  description = "Name of the project for the network. Useful for shared VPC. Default is var.project."
  default     = ""
}

variable subnetwork {
  description = "The subnetwork to deploy to"
  default     = "default"
}

variable region {
  description = "The region to create the nat gateway instance in."
}

variable zone {
  description = "Override the zone used in the `region_params` map for the region."
  default     = ""
}

variable name {
  description = "Prefix added to the resource names, for example 'prod-'. By default, resources will be named in the form of '<name>nat-gateway-<zone>'"
  default     = ""
}

variable ip_address_name {
  description = "Name of an existing reserved external address to use."
  default     = ""
}

variable tags {
  description = "Additional compute instance network tags to apply route to."
  type        = "list"
  default     = []
}

variable route_priority {
  description = "The priority for the Compute Engine Route"
  default     = 800
}

variable machine_type {
  description = "The machine type for the NAT gateway instance"
  default     = "n1-standard-1"
}

variable service_account_email {
  default = "default"
}

variable compute_image {
  description = "Image used for NAT compute VMs."
  default     = "debian-cloud/debian-9"
}

variable ip {
  description = "Override the internal IP. If not provided, an internal IP will automatically be assigned."
  default     = ""
}

variable squid_enabled {
  description = "Enable squid3 proxy on port 3128."
  default     = "false"
}

variable squid_config {
  description = "The squid config file to use. If not specifed the module file config/squid.conf will be used."
  default     = ""
}

variable l2tp_enabled {
  description = "Enable L2TP/IPSec connection proxy."
  default     = "false"
}

variable l2tp_kms_keyring {
  description = "KMS keyring name"
  default = ""
}

variable l2tp_kms_key {
  description = "KMS key name"
  default = ""
}

variable l2tp_kms_location {
  description = "KMS keyring location"
  default = "global"
}

variable l2tp_ip_ciphertext {
  description = "Encrypted L2TP endpoint IP address"
  default = ""
}

variable l2tp_username_ciphertext {
  description = "Encrypted IPSec username"
  default = ""
}

variable l2tp_password_ciphertext {
  description = "Encrypted IPSec password"
  default = ""
}

variable l2tp_psk_ciphertext {
  description = "Encrypted L2TP Pre-shared key"
  default = ""
}

variable l2tp_ip_ranges {
  description = "L2TP routing"
  default = ["192.168.100.0/24"]
}

variable l2tp_gateway_id {
  description = "IPSec gateway ID"
  default = ""
}

variable l2tp_check_ip {
  description = "L2TP healthcheck gateway IP address"
  default = ""
}

variable ipsec_ike {
  description = "IKE option for IPSec"
  default = "3des-sha1-modp1024!"
}

variable ipsec_esp {
  description = "ESP option for IPSec"
  default = "3des-sha1!"
}

variable metadata {
  description = "Metadata to be attached to the NAT gateway instance"
  type        = "map"
  default     = {}
}

variable ssh_source_ranges {
  description = "Network ranges to allow SSH from"
  type        = "list"
  default     = ["0.0.0.0/0"]
}

variable region_params {
  description = "Map of default zones and IPs for each region. Can be overridden using the `zone` and `ip` variables."
  type        = "map"

  default = {
    asia-east1 = {
      zone = "asia-east1-b"
    }

    asia-northeast1 = {
      zone = "asia-northeast1-b"
    }

    asia-south1 = {
      zone = "asia-south1-b"
    }

    asia-southeast1 = {
      zone = "asia-southeast1-b"
    }

    australia-southeast1 = {
      zone = "australia-southeast1-b"
    }

    europe-north1 = {
      zone = "europe-north1-b"
    }

    europe-west1 = {
      zone = "europe-west1-b"
    }

    europe-west2 = {
      zone = "europe-west2-b"
    }

    europe-west3 = {
      zone = "europe-west3-b"
    }

    europe-west4 = {
      zone = "europe-west4-b"
    }

    northamerica-northeast1 = {
      zone = "northamerica-northeast1-b"
    }

    southamerica-east1 = {
      zone = "southamerica-east1-b"
    }

    us-central1 = {
      zone = "us-central1-f"
    }

    us-east1 = {
      zone = "us-east1-b"
    }

    us-east4 = {
      zone = "us-east4-b"
    }

    us-west1 = {
      zone = "us-west1-b"
    }
  }
}
