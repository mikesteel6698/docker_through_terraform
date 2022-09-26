terraform {
  backend "s3" {
    bucket         = "cicdbucket6698"
    key            = "terraform-state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lock_table"
    encrypt        = true
  }
}

module "testvpc_module" {
  source            = "./modules/vpc_module"
  vpc_cidr          = var.test_vpc_cidr
  availability_zone = var.test_az[*]
}

module "testsg_module" {
  source = "./modules/sg_module"
  vpc_id = module.testvpc_module.vpc_id
}

resource "aws_instance" "pro_1" {
  depends_on = [
    aws_instance.pro_2
  ]
  ami               = var.ami_id
  instance_type     = var.instance_type
  availability_zone = var.test_az[0]
  key_name          = var.key
  root_block_device {
    volume_size = var.root_volume_size
  }
  subnet_id                   = module.testvpc_module.subnet_id[0]
  vpc_security_group_ids      = [module.testsg_module.sg_id]
  associate_public_ip_address = true
  tags = {
    name = "ansible_host"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y software-properties-common",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt install ansible -y",
      "sudo apt install python3 -y",
      "sudo apt install python3-pip -y",
      "sudo pip3 install boto3",
      "sudo apt install unzip",
      "mkdir ${var.home_directory}/.aws",
      "mkdir ${var.home_directory}/ansible",
      "sudo mkdir /tmp/prometheus"
    ]
  }

  provisioner "file" {
    source      = "./ansible"
    destination = var.home_directory
  }

  provisioner "file" {
    source      = "../new.pem"
    destination = "${var.home_directory}/.ssh/new.pem"
  }

  provisioner "file" {
    source      = "../config"
    destination = "${var.home_directory}/.aws/config"
  }

  provisioner "file" {
    source      = "../credentials"
    destination = "${var.home_directory}/.aws/credentials"
  }

  provisioner "file" {
    source      = "../prometheus.yml"
    destination = "${var.home_directory}/prometheus.yml"
  }

  provisioner "file" {
    source = "./docker-compose.yaml"
    destination = "${var.home_directory}/docker-compose.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo unzip ${var.home_directory}/ansible/awscli-exe-linux-x86_64.zip -d ${var.home_directory}/ansible/",
      "sudo ${var.home_directory}/ansible/aws/install",
      "chmod 400 ${var.home_directory}/.ssh/new.pem",
      "cd ${var.home_directory}/ansible/inventory/",
      "ansible-playbook dockerjdk11.yml"
    ]
  }
  connection {
    type        = "ssh"
    user        = var.username
    private_key = file("../new.pem")
    host        = self.public_ip
  }
}

resource "aws_instance" "pro_2" {
  ami               = var.ami_id
  instance_type     = var.instance_type
  availability_zone = var.test_az[1]
  key_name          = var.key
  root_block_device {
    volume_size = var.root_volume_size
  }
  subnet_id                   = module.testvpc_module.subnet_id[1]
  vpc_security_group_ids      = [module.testsg_module.sg_id]
  associate_public_ip_address = true
  tags = {
    name = var.username
  }
}
