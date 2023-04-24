resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_sensitive_file" "id_rsa" {
  filename = "ssh_key"
  file_permission = "600"
  content = tls_private_key.ssh-key.private_key_pem
}

resource "yandex_compute_instance_group" "ig-1" {
  name               = "fixed-ig-with-balancer"
  folder_id = var.yandex_folder_id
  service_account_id = "${yandex_iam_service_account.sa-ig1.id}"
  instance_template {
    platform_id = "standard-v3"
    resources {
      memory = 4
      cores  = 2
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = var.iso_id
      }
    }

    network_interface {
      subnet_ids = ["${yandex_vpc_subnet.yc-subnet-a.id}"]
      nat = true
    }

    metadata = {
      user-data = data.template_file.cloud_init.rendered
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = var.yandex_zone
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  load_balancer {
    target_group_name        = "target-group"
    target_group_description = "load balancer target group"
  }
}
data "template_file" "cloud_init" {
  template = file("cloud_init_config.tpl")
  vars = {
    user    = var.user
    ssh_key = tls_private_key.ssh-key.public_key_openssh
  }
}