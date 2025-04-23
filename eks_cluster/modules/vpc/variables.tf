variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "allowed_ssh_cidr" {
  type = list(string)
}

variable "allowed_udp_cidr" {
  type = list(string)
}