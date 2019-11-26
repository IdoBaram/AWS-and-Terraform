#Backend
terraform {
  backend "s3" {
    bucket = "opscool-tfstate"
    key    = "terraform.state"
    region = "us-east-1"
    encrypt = true
  }
}

###################
#Provider
provider "aws" {
	region = "${var.region}"
	access_key = var.aws_access_key
	secret_key = var.aws_secret_key	
}

data "aws_ami" "ubuntu" {
	most_recent = true
	
	
	filter {
		name = "name"
		values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
	}
		
	filter {
		name = "virtualization-type"
		values = ["hvm"]
	}
	
	owners = ["099720109477"] # Canonical
}
data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

module "ec2_keys" {
    source = ".\\modules\\keys"
}

module "s3_bucket" {
    source = ".\\modules\\s3"
}

resource "aws_vpc" "vpc1" {
  cidr_block = "10.1.0.0/16"
  enable_dns_hostnames = "true"

  tags = { 
	Name = "Vpc lesson 3"
	Description = "Vpc for lesson 3"
  }
}

resource "aws_subnet" "private1" {
  vpc_id     = "${aws_vpc.vpc1.id}"
  cidr_block = "10.1.0.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Priavte_Sub1"
	Description = "Priavte subnet 2"
  }
}

resource "aws_subnet" "public1" {
  vpc_id     = "${aws_vpc.vpc1.id}"
  cidr_block = "10.1.10.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Public_Sub1"
	Description = "Public subnet 1"
  }
}

resource "aws_subnet" "private2" {
  vpc_id     = "${aws_vpc.vpc1.id}"
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "Priavte_Sub2"
	Description = "Priavte subnet 2"
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = "${aws_vpc.vpc1.id}"
  cidr_block = "10.1.11.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "Public_Sub2"
	Description = "Public subnet 2"
  }
}

resource "aws_internet_gateway" "web-igw" {
  vpc_id = "${aws_vpc.vpc1.id}"

  tags = {
	Name = "vpc1-igw" 
	Description = "Internet gateway for lesson 3"
  }
}

resource "aws_security_group" "elb-sg" {
  name   = "web_balancer_sg"
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
	Name = "web_balancer_sg"
	Description = "Load balancer security group for lesson 3"
  }
}

resource "aws_route_table" "web-rtb" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web-igw.id
  }

  tags = {
	Name = "web_rtb"
	Description = "Route table for public subnets"
  }
}

resource "aws_route_table_association" "rta-public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.web-rtb.id
}

resource "aws_route_table_association" "rta-public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.web-rtb.id
}

resource "aws_route_table" "db_rtb" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.private_natgw.id
  }

  tags = {
	Name = "db-rtb"
	Description = "Route table for private subnets"
  }
}

resource "aws_route_table_association" "rta-private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.db_rtb.id
}

resource "aws_route_table_association" "rta-private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.db_rtb.id
}

resource "aws_security_group" "nginx_sg" {
  name   = "nginx-sg"
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
	Name = "nginx-sg"
	Description = "Security group to access nginx from anywhere"
  }
}

resource "aws_nat_gateway" "private_natgw" {
  allocation_id = "${aws_eip.nat_gw.id}"
  subnet_id     = "${aws_subnet.public1.id}"
}

resource "aws_eip" "nat_gw" {
  vpc      = true
}

resource "aws_instance" "web1" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]
  subnet_id = aws_subnet.public1.id
  associate_public_ip_address = "true"
  key_name = module.ec2_keys.ec2_key
  iam_instance_profile = "${module.s3_bucket.nginx_to_s3_profile.name}"
  user_data       = "${file("provision.sh")}"
  tags = {
			Name = "web1"
			Owner = "${data.aws_caller_identity.current.account_id}"
			Purpose = "OpsSchool training"
	}
  
}

resource "aws_instance" "web2" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  availability_zone = data.aws_availability_zones.available.names[1]
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]
  subnet_id = aws_subnet.public2.id
  associate_public_ip_address = "true"
  key_name = module.ec2_keys.ec2_key
  iam_instance_profile = "${module.s3_bucket.nginx_to_s3_profile.name}"
  tags = {
			Name = "web2"
			Owner = "${data.aws_caller_identity.current.account_id}"
			Purpose = "OpsSchool training"
	}
  user_data = "${file("provision.sh")}"
}

resource "aws_instance" "db1" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  availability_zone = data.aws_availability_zones.available.names[0]
  subnet_id = aws_subnet.private1.id
  key_name = module.ec2_keys.ec2_key
  tags = {
			Name = "db1"
			Owner = "${data.aws_caller_identity.current.account_id}"
			Purpose = "OpsSchool training"
	}
}

resource "aws_instance" "db2" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  availability_zone = data.aws_availability_zones.available.names[1]
  subnet_id = aws_subnet.private2.id
  key_name = module.ec2_keys.ec2_key
  tags = {
			Name = "db2"
			Owner = "${data.aws_caller_identity.current.account_id}"
			Purpose = "OpsSchool training"
	}
}

resource "aws_elb" "web-balancer" {
  name = "web-elb"

  subnets         = [aws_subnet.public1.id, aws_subnet.public2.id]
  security_groups = [aws_security_group.elb-sg.id]
  instances       = [aws_instance.web1.id,aws_instance.web2.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  tags = { Name = "Web load balancer" }

}

resource "aws_lb_cookie_stickiness_policy" "elb-stick" {
  name          = "elb-stick"
  load_balancer = "${aws_elb.web-balancer.id}"
  lb_port       = 80
  cookie_expiration_period = 60
}