
# ☁️ Apache Kafka en EC2 (Instancia Spot) con Terraform

Este proyecto despliega una instancia EC2 barata (tipo spot) en AWS, instala Apache Kafka y permite probarlo usando `tmux`, producer y consumer desde la consola.

---

## 🚀 1. Crear EC2 con Terraform

### `main.tf`

```hcl
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
  ami                         = "ami-08f9a9c699d2ab3f9"
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
              yum update -y
              amazon-linux-extras enable corretto8
              yum install -y java-1.8.0-amazon-corretto tmux wget tar tree
              cd /home/ec2-user
              wget https://archive.apache.org/dist/kafka/3.7.0/kafka_2.13-3.7.0.tgz
              tar -xvzf kafka_2.13-3.7.0.tgz
              chown -R ec2-user:ec2-user kafka_2.13-3.7.0
              cd /home/ec2-user/kafka_2.13-3.7.0
              bin/zookeeper-server-start.sh config/zookeeper.properties > zk.log 2>&1 &
              bin/kafka-server-start.sh config/server.properties > kafka.log 2>&1 &
              EOF
}

# MIT License
# Copyright (c) 2025 Jose Magariño
# See LICENSE file for more details.
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

## 📨 3. Probar Kafka

### Crear un topic

```bash
cd kafka_2.13-3.7.0
bin/kafka-topics.sh --create --topic test --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
```

### Enviar mensajes (producer)

```bash
cd kafka_2.13-3.7.0
bin/kafka-console-producer.sh --topic test --bootstrap-server localhost:9092
```

Escribe mensajes como:

```
mensaje 1
mensaje 2
```

### Leer mensajes (consumer)

```bash
bin/kafka-console-consumer.sh --topic test --from-beginning --bootstrap-server localhost:9092
```

---

## 📨 4. Probar script python

### Intalar python y confluent-kafka

```bash
sudo yum install -y python3
pip install confluent-kafka
```

### Crear un script

```bash
cd kafka_2.13-3.7.0
vi producer.py
from confluent_kafka import Producer

p = Producer({'bootstrap.servers': 'localhost:9092'})

def delivery_report(err, msg):
    if err:
        print('❌ Error al enviar mensaje:', err)
    else:
        print(f'✅ Mensaje enviado a {msg.topic()} [{msg.partition()}]')

for i in range(5):
    p.produce('test', key=str(i), value=f'Mensaje número {i}', callback=delivery_report)

p.flush()

```

### Crear un script

```bash
cd kafka_2.13-3.7.0
vi consumer.py
from confluent_kafka import Consumer

c = Consumer({
    'bootstrap.servers': 'localhost:9092',
    'group.id': 'grupo-python',
    'auto.offset.reset': 'earliest'
})

c.subscribe(['test'])

print("⏳ Esperando mensajes en el topic 'test'...\n")

try:
    while True:
        msg = c.poll(1.0)
        if msg is None:
            continue
        if msg.error():
            print("⚠️ Error:", msg.error())
        else:
            print(f"📥 Recibido: {msg.value().decode('utf-8')} (clave: {msg.key()})")
except KeyboardInterrupt:
    print("🛑 Finalizando consumidor...")
finally:
    c.close()

```

### Probar un scripts

```bash
cd kafka_2.13-3.7.0
python consumer.py

En otra ventana
python producer.py

```

---

## 🧠 Notas sobre Kafka

- Crear alias python=python3 y alias pip=pip3
- Scripts Antes de ejecutar los scripts crear el topico.
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