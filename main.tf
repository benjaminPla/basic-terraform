provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}
resource "aws_instance" "simple_front" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo apt install -y docker-compose
    echo 'version: "3"
services:
  mongo:
    image: mongo:latest
    volumes:
      - ~/data/db:/data/db
  api:
    image: benjaminpla/simple_api:latest
    ports:
      - 80:3000
    environment:
      - MONGO_URL=mongodb://mongo:27017' | sudo tee ./docker-compose.yml
    sudo docker-compose up -d
  EOF
  vpc_security_group_ids = [aws_security_group.security_group.id]
  tags = {
    Name = "simple_front"
  }
}
resource "aws_eip" "eip" {
  instance = aws_instance.simple_front.id
}
resource "aws_security_group" "security_group" {
  name        = "simple_front"
  description = "Allow all HTTP, HTTPS and custom SSH access"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
output "public_ip" {
  value = aws_eip.eip.public_ip
}
