# Application configuration | variables.tf

variable "server_region" {
  description = "Region to deploy server"
  type        = string
  default     = "us-west-2"
}


variable "app_name" {
  type        = string
  description = "Application name"
}
variable "app_environment" {
  type        = string
  description = "Application environment"
}
variable "admin_sources_cidr" {
  type        = list(string)
  description = "List of IPv4 CIDR blocks from which to allow admin access"
}
variable "app_sources_cidr" {
  type        = list(string)
  description = "List of IPv4 CIDR blocks from which to allow application access"
}