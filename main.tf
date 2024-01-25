#create vpc using terraform
resource "aws_vpc" "pavan" {
  cidr_block       = "134.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = "main"
  }
}

#creating subnets
resource "aws_subnet" "public-subnet-1" {
  vpc_id     = aws_vpc.pavan.id
  cidr_block = "134.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id     = aws_vpc.pavan.id
  cidr_block = "134.0.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "public-subnet-2"
  }
}

#create internetgateway
resource "aws_internet_gateway" "pavan-gw" {
  vpc_id = aws_vpc.pavan.id

  tags = {
    Name = "pavan-gw"
  }
}

#create route table to internet gateway
resource "aws_route_table" "pavan-rt" {
  vpc_id = aws_vpc.pavan.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pavan-gw.id
  }

  tags = {
    Name = "pavan-rt"
  }
}

#route table associations
resource "aws_route_table_association" "pavan-association-1" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.pavan-rt.id
}

resource "aws_route_table_association" "pavan-association-2" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.pavan-rt.id
}

#sg
resource "aws_security_group" "pavan-sg" {
  name        = "pavan-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.pavan.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
    ingress {
    description      = "SSH"
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
   
  }

  tags = {
    Name = "pavan-sg"
  }
}

#ec2's

resource "aws_instance" "public-instance-1" {
    ami = ""
    instance_type = ""
    key_name = ""
    subnet_id = " ${aws_subnet.public-subnet-1.id}"

    root_block_device {
      volume_size = "15"
      volume_type = "gp2"
    }
    tags = {
      Name ="pavan"
    }
  
}

resource "aws_instance" "public-instance-2" {
    ami = ""
    instance_type = ""
    key_name = ""
    subnet_id = " ${aws_subnet.public-subnet-2.id}"

    root_block_device {
      volume_size = "15"
      volume_type = "gp2"
    }
    tags = {
      Name ="pavan"
    }
}

#create loadbalancer
resource "aws_lb" "pavan-lb" {
  name               = "pavan-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.pavan-sg.id]
  subnets            = [aws_subnet.public-subnet-1.id,aws_subnet.public-subnet-2.id]

  tags = {
    Environment = "production"
  }
}

#create target group
resource "aws_lb_target_group" "pavan-tg" {
  name     = "pavan-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.pavan.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

#create lb-tg-attach
resource "aws_lb_target_group_attachment" "pavan-att-1" {
  target_group_arn = aws_lb_target_group.pavan-tg.arn
  target_id        = aws_instance.public-instance-1
  port             = 80
}

resource "aws_lb_target_group_attachment" "pavan-att-2" {
  target_group_arn = aws_lb_target_group.pavan-tg.arn
  target_id        = aws_instance.public-instance-2
  port             = 80
}

#lb listener
resource "aws_lb_listener" "pavan-listner" {
  load_balancer_arn = aws_lb.pavan-lb.arn
  port              = "80"
  protocol          = "HTTPS"
 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pavan-tg.arn
  }
}

output "loadbalancedns" {
  value = "aws_lb.pavan-lb.dns_name"
  
}

