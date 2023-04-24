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