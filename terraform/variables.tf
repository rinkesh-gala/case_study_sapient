variable "gcp_project" {
  type        = string
  description = "default gcp project"
}

variable "gcp_region" {
  type        = string
  description = "default deployment gcp region"
}

variable "gcp_zone" {
    type = string
    description = "default deployment gcp zone"
}

variable "whitelist_ip" {
  type = list(string)
  description = "list of ip which needs to be whitelisted"
}