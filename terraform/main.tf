#----------------------
# VPC & Networking 
# ---------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "main-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "main-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = { Nanme = "public_subnet" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "route-association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id

}

# ----------
# Security Groups
# ----------

resource "aws_security_group" "sg" {
  name        = "ec2-sg"
  description = "sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jenkins"
  }
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    description = "Flask App"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

# -----------------------
# Key Pair
# ------------------------
resource "aws_key_pair" "key" {
  key_name   = "my-key"
  public_key = file("~/.ssh/ec2-key.pub")
}

# -----------------------
# EC2 Instance
# -------------------------

resource "aws_instance" "aws_ec2" {
  ami                    = "ami-0ec10929233384c7f"
  subnet_id              = aws_subnet.public.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = aws_key_pair.key.id

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
  user_data_replace_on_change = true

}

# --------------
# Elastic IP
# --------------

resource "aws_eip" "flask_eip" {
  domain = "vpc"
  tags   = { Name = "eip" }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.aws_ec2.id
  allocation_id = aws_eip.flask_eip.id
}

