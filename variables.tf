variable "aws_profile" {
}

variable "aws_region" {
}

variable "vpc_cidr" {
}

data "aws_availability_zones" "available" {
}

variable "cidrs" {
  type = map(string)
}

data "http" "myIP" {
  url = "http://ipv4.icanhazip.com"
}

variable "AZ" {
}

variable "key_name" {
}

variable "ubuntu_instance_type" {
}

variable "ubuntu_count" {
}

variable "public_key_path" {
}

variable "bigip_instance_type" {
}

variable "bigip_count" {
}

variable "bigip_ami_prod_code" {
}

variable "bigip_ami_name_filt" {
}

variable "bigip_admin" {
}

variable "do_rpm" {
}

variable "as3_rpm" {
}

