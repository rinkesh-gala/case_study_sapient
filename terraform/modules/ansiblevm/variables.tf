variable "vpc_config" {
  description = " vpc details from module networking"
}

variable "subnet_config" {
  description = " subnet details from module networking"
}

variable "gcp_project" {
  type        = string
  #default     = "flowing-coil-348605"
  description = "default gcp project"
}

variable "gcp_region" {
  type        = string
  #default     = "asia-southeast1"
  description = "default deployment gcp region"
}

variable "gcp_zone" {
    type = string
    #default = "asia-southeast1-a"
    description = "default deployment gcp zone"
}

/*variable "whitelist_ip" {
  type = list(string)
  description = "list of ip which needs to be whitelisted"
}*/