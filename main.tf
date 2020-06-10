provider "aws" {
	 region = "ap-south-1"
	 profile = "lwprofile"
}


#Creating Security Group
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
  # Creating EBS

 resource "aws_ebs_volume" "example" {
    availability_zone = "ap-south-1a"
    size = 1
 
    tags = {
      Name = "VolumeForTerraform"
   }
  }
 
  resource "aws_volume_attachment" "ebs_attached" {
    device_name = "/dev/sdh"
    volume_id   = "${aws_ebs_volume.example.id}"
    instance_id = "${aws_instance.webserver.id}"
  }



#Creating an AWS instance

resource "aws_instance" "webserver" {
	ami = "ami-052c08d70def0ac62"
	instance_type = "t2.micro"
	availability_zone = "ap-south-1a"
	security_groups = ["${aws_security_group.allow_http.name}"]
	key_name = "projectGP"
	user_data = <<-EOF
		#! /bin/bash
		 yum install httpd unzip parted -y
		 systemctl start httpd
		 systemctl enable httpd
		 #addpart /dev/sdh 1 2050 2097150
		 #mkfs.ext4 /dev/sdh1 
		# mount /dev/sdh1	/var/www/html
	EOF
	
	tags = {
		Name = "webserver"
	}

}
####### s3 bucket
resource "s3-bucket" "sonubucket" {
	bucket = "sonu32111"
	acl = "public"
	region = "ap-south-1"
}
#object
resource "s3-bucket" "sonubucketobject" {
	bucket = "sonu32111"
	key = "sonu.jpg"
	source = "sonu.jpg"
	acl = "public-read"
}


