output "ec2_key" {
    value = "${aws_key_pair.lesson3_key.key_name}"
}