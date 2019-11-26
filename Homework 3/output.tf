output "aws_instance1_public_dns" {
 value = aws_instance.web2.public_dns
}

output "aws_instance2_public_dns" {
 value = aws_instance.web1.public_dns
}

output "aws_instance_private_dns" {
 value = aws_instance.db1.private_dns
}

output "aws_instance2_private_dns" {
 value = aws_instance.db2.private_dns
}

output "aws_elb_public_dns" {
    value = aws_elb.web-balancer.dns_name
  }