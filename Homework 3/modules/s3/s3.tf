resource "aws_s3_bucket" "ngnix_logs" {
  bucket = "ngnixlogstf"
  acl    = "private"
  force_destroy = true

  tags = {
    Name = "Ngnix Logs bucket"
  }
}

resource "aws_iam_role" "nginx_to_s3" {
  name = "nginx_to_s3"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "nginx_to_s3_profile" {
  name = "nginx_profile"
  role = aws_iam_role.nginx_to_s3.name
}

resource "aws_iam_role_policy" "allow_s3_all" {
  name = "allow_s3_all"
  role = aws_iam_role.nginx_to_s3.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
                "arn:aws:s3:::ngnixlogstf",
                "arn:aws:s3:::ngnixlogstf/*"
            ]
    }
  ]
}
EOF

  }