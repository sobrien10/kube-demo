provider "aws" {
  region  = "eu-west-2"
}

#Configure the VPC and Public Subnets
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"

  name = "${var.prefix}-k8s-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-2a"]
  public_subnets  = ["10.0.1.0/24"]

  enable_nat_gateway = false

  tags = {
    Environment = "OB1-k8s-vpc"
  }
}

#Configure the security Group
resource "aws_security_group" "k8s" {
  name   = "${var.prefix}-k8s-SecurityGroup"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "OB1-k8s-SecurityGroup"
  }
}

data "template_file" "user_data1" {
  template = "${file("${path.module}/userdata-master.tmpl")}"

}

resource "aws_instance" "k8s-Master" {
  ami = "ami-ee6a718a"
  instance_type = "t2.medium"
  subnet_id   = module.vpc.public_subnets[0]
  private_ip = "10.0.1.10"
  key_name   = "${var.ssh_key_name}"
  user_data = "${data.template_file.user_data1.rendered}"
  security_groups = [ aws_security_group.k8s.id ]
    tags = {
    Name = "k8s-Master"
  }
}
