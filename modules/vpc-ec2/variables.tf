variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidr" {
  description = "list of CIDRs for public subnets "
  type        = list(string)
}

variable "private_subnet_cidr" {
  description = "list of CIDRs for private subnets "
  type        = list(string)
}

variable "instance_type" {
  default = "t2.micro"
  type    = string
}

variable "associate_public_ip" {
  default = true
  type    = bool
}

