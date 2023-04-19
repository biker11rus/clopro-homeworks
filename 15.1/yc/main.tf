terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
    }
  }
}
provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id                 = var.yandex_cloud_id
  folder_id                = var.yandex_folder_id
  zone                     = var.yandex_zone
}
resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_sensitive_file" "id_rsa" {
  filename = "ssh_key"
  file_permission = "600"
  content = tls_private_key.ssh-key.private_key_pem
}

data "template_file" "cloud_init" {
  template = file("cloud_init_config.tpl")
  vars = {
    user    = var.user
    ssh_key = tls_private_key.ssh-key.public_key_openssh
  }
}

resource "yandex_vpc_network" "yc-vpc" {
  name        = "yc_vpc_network"    
}

resource "yandex_vpc_subnet" "yc-subnet-a" {
  name           = "public"
  description    = "public-net"
  v4_cidr_blocks = ["192.168.10.0/24"]
  zone                     = var.yandex_zone
  network_id     = "${yandex_vpc_network.yc-vpc.id}"
}

resource "yandex_compute_instance" "nat-instance" {
  name = "nat-instance"
  zone = var.yandex_zone
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd8oi1ha2tq6bh8tfco4"
      size     = 20
    }
  }
  network_interface {
    subnet_id = "${yandex_vpc_subnet.yc-subnet-a.id}"
    nat       = true
    ip_address = "192.168.10.254"
  }
  metadata = {
    user-data = data.template_file.cloud_init.rendered
  }
}

resource "yandex_compute_instance" "test-vm-pub" {
  name = "test-vm-pub"
  zone = var.yandex_zone
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = var.iso_id
      size     = 20
    }
  }
  network_interface {
    subnet_id = "${yandex_vpc_subnet.yc-subnet-a.id}"
    nat       = true
  }
  metadata = {
    user-data = data.template_file.cloud_init.rendered
  }
  provisioner "file" {
    content = tls_private_key.ssh-key.private_key_pem
    destination = pathexpand(var.private_key_path)
    connection {
      type        = "ssh"
      host        = self.network_interface.0.nat_ip_address
      user        = var.user
      private_key = tls_private_key.ssh-key.private_key_openssh
    }
  }
  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/rkhozyainov/.ssh/id_rsa",
    ]
    connection {
      type        = "ssh"
      host        = self.network_interface.0.nat_ip_address
      user        = var.user
      private_key = tls_private_key.ssh-key.private_key_openssh
    }
  }
}

resource "yandex_vpc_subnet" "yc-subnet-b" {
  name           = "private"
  description    = "private-net"
  v4_cidr_blocks = ["192.168.20.0/24"]
  zone                     = var.yandex_zone
  network_id     = "${yandex_vpc_network.yc-vpc.id}"
  route_table_id = yandex_vpc_route_table.yc-rt.id
}

resource "yandex_vpc_route_table" "yc-rt" {
  name       = "yc-rt"
  network_id = "${yandex_vpc_network.yc-vpc.id}"

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
}

resource "yandex_compute_instance" "test-vm-priv" {
  name = "test-vm-priv"
  zone = var.yandex_zone
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = var.iso_id
      size     = 20
    }
  }
  network_interface {
    subnet_id = "${yandex_vpc_subnet.yc-subnet-b.id}"
  }
  metadata = {
    user-data = data.template_file.cloud_init.rendered
  }
}




