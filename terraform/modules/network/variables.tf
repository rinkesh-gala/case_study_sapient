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