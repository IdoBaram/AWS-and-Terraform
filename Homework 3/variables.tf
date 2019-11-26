variable "region" {
  description = "AWS region"
  default = "us-east-1"
}

variable "instance_type" {
    default = "t2.micro"
}
variable aws_access_key{}

variable aws_secret_key{}