provider "aws" {
  region = "eu-west-1" # Cambia según prefieras
}

resource "aws_security_group" "kafka_sg" {
  name        = "kafka-sg"
  description = "Security group for Kafka EC2 instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Abierto para SSH (solo para pruebas)
  }

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Kafka (abierto para pruebas, cuidado en prod)
  }

  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Zookeeper
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "kafka_spot" {
  ami                         = "ami-08f9a9c699d2ab3f9" # Ubuntu 22.04 LTS (us-east-1)
  instance_type               = "t3.large"
  key_name                    = "aws"
  vpc_security_group_ids      = [aws_security_group.kafka_sg.id]

  instance_market_options {
    market_type = "spot"
    spot_options {
      spot_instance_type = "one-time"
    }
  }

  tags = {
    Name = "Kafka-Spot-Instance"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo dnf install -y tree
              sudo yum update -y
              sudo amazon-linux-extras enable corretto8
              sudo yum install java-1.8.0-amazon-corretto -y
              wget https://archive.apache.org/dist/kafka/3.7.0/kafka_2.13-3.7.0.tgz
              tar -xvzf kafka_2.13-3.7.0.tgz
              cd kafka_2.13-3.7.0
              sudo yum install -y tmux
              EOF
}

# MIT License
# Copyright (c) 2025 Jose Magariño
# See LICENSE file for more details.