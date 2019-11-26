resource "tls_private_key" "lesson3_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lesson3_key" {
  key_name   = "terraformDemo"
  public_key = "${tls_private_key.lesson3_key.public_key_openssh}"
}

resource "local_file" "lesson3_key" {
  sensitive_content  = "${tls_private_key.lesson3_key.private_key_pem}"
  filename           = "lesson3.pem"
}