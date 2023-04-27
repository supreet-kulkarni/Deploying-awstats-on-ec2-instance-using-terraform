terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.74.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Creating VPC,name, CIDR and Tags
resource "aws_vpc" "dev" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "dev"
  }
}

# Creating Public Subnets in VPC
resource "aws_subnet" "dev-public-1" {
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1a"

  tags = {
    Name = "dev-public-1"
  }
}

resource "aws_subnet" "dev-public-2" {
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1b"

  tags = {
    Name = "dev-public-2"
  }
}

# Creating Internet Gateway in AWS VPC
resource "aws_internet_gateway" "dev-gw" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "dev"
  }
}

# Creating Route Tables for Internet gateway
resource "aws_route_table" "dev-public" {
  vpc_id = aws_vpc.dev.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev-gw.id
  }

  tags = {
    Name = "dev-public-1"
  }
}

# Creating Route Associations public subnets
resource "aws_route_table_association" "dev-public-1-a" {
  subnet_id      = aws_subnet.dev-public-1.id
  route_table_id = aws_route_table.dev-public.id
}

resource "aws_route_table_association" "dev-public-2-a" {
  subnet_id      = aws_subnet.dev-public-2.id
  route_table_id = aws_route_table.dev-public.id
}

#Creating security group
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.dev.id


   ingress {
      description      = "HTTPS"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      }


    ingress {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      }

   ingress {
      description      = "Ssh"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      }

    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  tags = {
    Name = "allow_web_ssh"
  }
}

# Creating EC2 instances in public subnets
resource "aws_instance" "web_server" {
  ami           = "ami-062df10d14676e201"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.dev-public-1.id}"
  security_groups = [aws_security_group.allow_web.id]
  key_name = "webkey-1"
  user_data = <<-EOF
                     #!/bin/bash
                     sudo su 
                     apt update
                     apt install apache2 –y
                     git clone https://github.com/eldy/AWStats.git
                     tar cvzf AWStats-7.9.tar.gz AWStats
                     tar xvzf  AWStats-7.9.tar.gz
                     cd AWStats/wwwroot/
                     cp -r icon /var/www/html/
                     chown www-data:www-data -R /var/www/html/icon/
                     a2enmod cgi
                     service apache2 restart
                     mv cgi-bin awstat
                     chown www-data:www-data -R awstat
                     mv awstat /usr/lib/cgi-bin
                     cd /usr/lib/cgi-bin/awstat
                     cp awstats.model.conf awstats.linux.conf
                     sed -i 's|LogFile="/var/log/httpd/mylog.log"|LogFile=" /var/log/apache2/access.log"|' awstats.linux.conf
                     sed -i 's|SiteDomain=""|SiteDomain="test.com" |' awstats.linux.conf
                     sed -i 's|AllowToUpdateStatsFromBrowser=0|AllowToUpdateStatsFromBrowser=1|' awstats.linux.conf
                     cd
                     /usr/bin/perl /usr/lib/cgi-bin/awstat/awstats.pl -config=linux -update
                EOF
  tags = {
    Name = "webserver"
  }
}

output "instance_ip_address" {
  value = aws_instance.web_server.public_ip
}
