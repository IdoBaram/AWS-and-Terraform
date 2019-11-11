variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "network_address_space" {
  default = "10.1.0.0/16"
}
variable "subnet1_address_space" {
  default = "10.1.0.0/24"
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "us-east-1"
}

data "aws_availability_zones" "available" {}

data "aws_ami" "aws-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}

resource "tls_private_key" "ops_server_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ops_server_key" {
  key_name   = "terraformDemo"
  public_key = "${tls_private_key.ops_server_key.public_key_openssh}"
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.network_address_space
  enable_dns_hostnames = "true"

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

}

resource "aws_subnet" "subnet1" {
  cidr_block              = var.subnet1_address_space
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[0]

}

resource "aws_ebs_volume" "Encrypted-EBS" {
  availability_zone = "us-east-1a"
  size              = 10
  type 				= "gp2"
  encrypted 		= "true"
  count				= 2
}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta-subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_security_group" "tf-sg" {
  name   = "tf_sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
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
}

resource "aws_instance" "Ops" {
  count					 = 2
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.tf-sg.id]
  key_name               = aws_key_pair.ops_server_key.key_name
  tags = {
			Name = "Ops${count.index}"
			Owner = "${data.aws_caller_identity.current.account_id}"
			Purpose = "OpsSchool training"
	}

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = "${tls_private_key.ops_server_key.private_key_pem}"

  }
provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
      "sudo echo '<header> <h1>Ops School</h1> <p>Rules!!!</p> <link rel=\"stylesheet\" href=\"index.css\"></header>' | sudo tee /usr/share/nginx/html/index.html",
	  "sudo echo '@import url(https://fonts.googleapis.com/css?family=Source+Sans+Pro:400,900);body { background: linear-gradient( rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5) ), url(https://scontent.fhfa2-2.fna.fbcdn.net/v/t1.0-9/13510916_1106213269417205_5784118891927942338_n.png?_nc_cat=103&_nc_oc=AQl3qGAjFOGFris1220j6do5Q_spIWQ404EYGGpigQieOMu0jz4-FuAqmG94ag_EIDs&_nc_ht=scontent.fhfa2-2.fna&oh=94c1bf5582c81dc7f86777af64d831b6&oe=5E5D9A41); background-size: cover; font-family: \"Source Sans Pro\", sans-serif;}header { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); color: white; text-align: center;}h1 { text-transform: uppercase; margin: 0; font-size: 3rem; white-space: nowrap;}p { margin: 0; font-size: 1.5rem;}' | sudo tee /usr/share/nginx/html/index.css"
    ]
  }
}

resource "aws_volume_attachment" "ebs_att" {
  count                       = 2
  device_name                 = "/dev/sdh"
  volume_id                   = "${element(aws_ebs_volume.Encrypted-EBS.*.id,count.index)}"
  instance_id                 = "${element(aws_instance.Ops.*.id,count.index)}"
}

output "aws_instance_public_dns" {
 value = aws_instance.Ops.*.public_dns
}