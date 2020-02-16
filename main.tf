provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source        = "github.com/ericdahl/tf-vpc"
  admin_ip_cidr = "${var.admin_cidr}"
}

resource "aws_network_interface" "static" {
  subnet_id = "${module.vpc.subnet_private1}"

  private_ips = ["10.0.101.4"]

  tags {
    Name = "${var.name}"
  }

  security_groups = [
    "${module.vpc.sg_allow_egress}",
    "${module.vpc.sg_allow_vpc}",
    "${module.vpc.sg_allow_22}",
    "${module.vpc.sg_allow_80}",
  ]
}

resource "aws_autoscaling_group" "default" {
  name = "demo-asg-static-ip"

  min_size         = "1"
  max_size         = "1"
  desired_capacity = "1"

  availability_zones = ["us-east-1a"]

  tag {
    key                 = "Name"
    value               = "${var.name}"
    propagate_at_launch = true
  }

  launch_template {
    id      = "${aws_launch_template.default.id}"
    version = "$Latest"
  }
}

resource "aws_launch_template" "default" {
  name = "${var.name}"

  image_id      = "${data.aws_ami.amazon_linux_2.image_id}"
  instance_type = "t3.small"
  key_name      = "${var.key_name}"

  monitoring {
    enabled = true
  }

  tags {
    Name = "${var.name}"
  }

  network_interfaces {
    network_interface_id = "${aws_network_interface.static.id}"
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  owners = ["137112412989"] # Amazon

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }

  filter {
    name = "name"

    values = [
      "amzn2-ami-hvm*",
    ]
  }
}

resource "aws_instance" "jumphost" {
  ami                    = "${data.aws_ami.amazon_linux_2.image_id}"
  instance_type          = "t3.small"
  subnet_id              = "${module.vpc.subnet_public1}"
  vpc_security_group_ids = ["${module.vpc.sg_allow_22}", "${module.vpc.sg_allow_egress}"]
  key_name               = "${var.key_name}"

  tags {
    Name = "jumphost"
  }
}
