provider "aws" {
  region = "ap-south-1"
  profile = "sonu"
}

resource "aws_key_pair" "deployer-key" {
  key_name  = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAtAV1nPk8st9FOGAN2kbgDSP9v7I6uHkXrX3OL5eR/Wzu0PGGFidBwZDw8lLBwbQojsR1OTt9DQgtAHQ01EB6A/6DUA+BGqIViRMDOdY8ZtTgr0R32cybgkYXqBH8xogbSIO6rRc3iaOMAo2/5RQqp2hgwlxKpMH7jjxVyo6rX5sZYaoabuLLTldiiAbrpKBlbfymCawUzySSnxno05rCr2NRql1wF2EyGkVKN4Dz40j6YsGGRyFjTbgbBJJTBW1Q9tU6OVhoI9mg9fJQwvdyp72Xzl2al3Z/t1fuH0/wCSgbz4AMS9FUEPWwNCa3kgLuBTQXkF2aEvNbwtT20+hzbQ== rsa-key-20200615"

}

#########Creating Security Group################
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"


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

  tags = {
    Name = "allow_http"
  }
}
################## end Security Group################

resource "aws_instance" "instance1" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "deployer-key"
  security_groups = ["${aws_security_group.allow_http.name}"]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/home/ec2-user/project/deployer-key.pem")
    host     = aws_instance.instance1.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "lwos1"
  }

}


resource "aws_ebs_volume" "esb1" {
  availability_zone = aws_instance.instance1.availability_zone
  size              = 1
  tags = {
    Name = "linstance1s"
  }
}


resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.esb1.id
  instance_id = aws_instance.instance1.id
  force_detach = true
}


output "myos_ip" {
  value = aws_instance.instance1.public_ip
}


resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.instance1.public_ip} > publicip.txt"
  	}
}



resource "null_resource" "nullremote3"  {

depends_on = [
    aws_volume_attachment.ebs_att,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/home/ec2-user/project/deployer-key.pem")
    host     = aws_instance.instance1.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/vimallinuxworld13/multicloud.git /var/www/html/"
    ]
  }
}
########
#Creating_S3_Bucket_and_CloudFront


resource "aws_s3_bucket" "bucket" {
  bucket = "sonu321qke"
  acl = "private"
  region = "ap-south-1"
}

resource "aws_s3_bucket_object" "object" {
        bucket = aws_s3_bucket.bucket.id
        key = "vimalsir.jpg"
        source = "VimalSir.JPG"
}

############

############ cloudfront########3

locals {
  s3_origin_id = "myS3Origin"
}
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "OAI"
}
resource "aws_cloudfront_distribution" "s3_distribution" {
origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
enabled             = true
  is_ipv6_enabled     = true
default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
forwarded_values {
      query_string = false
cookies {
        forward = "none"
      }
    }
viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
viewer_certificate {
    cloudfront_default_certificate = true
  }
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }
statement {
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.bucket.arn}"]
principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }
}
resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}



##############
resource "null_resource" "nulllocal1"  {


depends_on = [
    null_resource.nullremote3,
  ]

	provisioner "local-exec" {
	    command = "dig  ${aws_instance.instance1.public_ip}"
  	}
}





