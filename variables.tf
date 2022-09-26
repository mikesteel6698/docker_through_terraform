variable "test_vpc_cidr" {
  default = "10.0.0.0/16"
  type    = string
}

variable "test_az" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "ami_id" {
  default = "ami-08d4ac5b634553e16"
  type    = string
}

variable "instance_type" {
  default = "t2.micro"
  type    = string
}

variable "key" {
  type = string
  default = "new"
}

variable "root_volume_size" {
  type    = number
  default = 15
}

variable "home_directory" {
  type = string
  default = "/home/ubuntu"
}

variable "username" {
  type = string
  default = "ubuntu"
}

variable "nodes_tags" {
  type    = string
  default = "ubuntu_1"
}
