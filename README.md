
# ☁️ Apache Kafka en EC2 (Instancia Spot) con Terraform

Este proyecto despliega una instancia EC2 barata (tipo spot) en AWS, instala Apache Kafka y permite probarlo usando `tmux`, producer y consumer desde la consola.

---

## 🚀 1. Crear EC2 con Terraform

### `main.tf`

```hcl
provider "aws" {
  region = "eu-west-1"
}

resource "aws_key_pair" "kafka_key" {
  key_name   = "kafka-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "kafka_sg" {
  name        = "kafka-sg"
  description = "Allow SSH, Kafka and Zookeeper"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "kafka_spot" {
  ami                         = "ami-053b0d53c279acc90" # Ubuntu 22.04 (eu-west-1)
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.kafka_key.key_name
  vpc_security_group_ids      = [aws_security_group.kafka_sg.id]
  associate_public_ip_address = true

  instance_market_options {
    market_type = "spot"
    spot_options {
      spot_instance_type = "one-time"
    }
  }

  tags = {
    Name = "Kafka-Spot"
  }
}
```

---

## 🧑‍💻 2. Comandos Terraform

```bash
terraform init
terraform apply -auto-approve
terraform destroy -auto-approve
```

Conéctate por SSH:

```bash
ssh -i ~/.ssh/id_rsa ubuntu@<IP_PUBLICA>
```

---

## ☕ 3. Instalar Java y Kafka

### Java (Amazon Linux 2)

```bash
sudo yum update -y
sudo amazon-linux-extras enable corretto8
sudo yum install java-1.8.0-amazon-corretto -y
```

### Descargar Kafka

```bash
wget https://archive.apache.org/dist/kafka/3.7.0/kafka_2.13-3.7.0.tgz
tar -xvzf kafka_2.13-3.7.0.tgz
cd kafka_2.13-3.7.0
```

---

## 🔄 4. Ejecutar Kafka con `tmux`

```bash
sudo yum install -y tmux
tmux
```

### Ventana 1: Zookeeper

```bash
bin/zookeeper-server-start.sh config/zookeeper.properties
```

### Ventana 2: Kafka

```bash
tmux new-window
bin/kafka-server-start.sh config/server.properties
```

---

## 📨 5. Probar Kafka

### Crear un topic

```bash
bin/kafka-topics.sh --create --topic test --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
```

### Enviar mensajes (producer)

```bash
bin/kafka-console-producer.sh --topic test --bootstrap-server localhost:9092
```

Escribe mensajes como:

```
hola kafka
mensaje 2
```

### Leer mensajes (consumer)

```bash
tmux new-window
bin/kafka-console-consumer.sh --topic test --from-beginning --bootstrap-server localhost:9092
```

---

## 🧠 Notas sobre Kafka

- Kafka **no elimina mensajes automáticamente** tras consumirlos.
- Puedes leerlos múltiples veces con `--from-beginning`.
- Usa `Ctrl + C` para salir del producer o consumer.
- Usa `tmux` para que los servicios sigan activos si cierras la terminal.

---

## 📌 Recursos

- [Documentación oficial de Kafka](https://kafka.apache.org/documentation/)
- [Documentación de AWS Spot Instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

### MIT License
### Copyright (c) 2025 Jose Magariño
### See LICENSE file for more details.