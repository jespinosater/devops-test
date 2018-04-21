variable "access_key" {}

variable "secret_key" {}

variable "allowed_ip" {}

variable "ami" {
  default = "ami-f90a4880"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "region" {
  default = "eu-west-1"
}

variable "vpc_cidr" {
  default = "172.31.0.0/16"
}

variable "vpc_subnet_public_cidr" {
  default = "172.31.0.0/24"
}

variable "vpc_subnet_private_cidr" {
  default = "172.31.1.0/24"
}

variable "remote_username" {
  default = "ubuntu"
}
