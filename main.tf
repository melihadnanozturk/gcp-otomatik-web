provider "google" {
  project = "sistemyon-odev"
  region  = "europe-west4"
}

resource "google_compute_instance" "webserver_vm" {
  name         = "sistem-yon-odev-vm" 
  machine_type = "e2-micro"
  zone         = "europe-west4-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = "default" 
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.public_ssh_key_path)}"
  }

  tags = ["webserver", "ssh", "http"]
}

resource "google_compute_instance" "webserver_vm_2" {
  name         = "sistem-yon-odev-vm-2"
  machine_type = "e2-micro"
  zone         = "europe-west4-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = "default"
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.public_ssh_key_path)}"
  }

  tags = ["webserver", "ssh", "http"]
}

resource "google_compute_firewall" "allow_ssh_http" {
  name    = "odev-ssh"
  network = "default"

  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  target_tags = ["ssh", "http"]
}

variable "ssh_username" {
  description = "VM'ye bağlanacak SSH kullanıcı adı."
  type        = string
  default     = "your-user-name"
}

variable "public_ssh_key_path" {
  description = "SSH anahtar dosya yolu "
  type        = string
  default     = "your-ssh-path"
}

resource "google_compute_instance_group" "webserver_group" {
  name      = "webserver-group"
  zone      = "europe-west4-a"
  instances = [
    google_compute_instance.webserver_vm.id,
    google_compute_instance.webserver_vm_2.id
  ]
  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_health_check" "http_health_check" {
  name               = "http-health-check"
  check_interval_sec = 5
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 2

  http_health_check {
    port = 80
  }
}

resource "google_compute_backend_service" "web_backend" {
  name                  = "web-backend"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 10
  health_checks         = [google_compute_health_check.http_health_check.id]
  backend {
    group = google_compute_instance_group.webserver_group.self_link
  }
}

resource "google_compute_url_map" "web_url_map" {
  name            = "web-url-map"
  default_service = google_compute_backend_service.web_backend.self_link
}

resource "google_compute_target_http_proxy" "web_http_proxy" {
  name    = "web-http-proxy"
  url_map = google_compute_url_map.web_url_map.self_link
}

resource "google_compute_global_address" "web_lb_ip" {
  name = "web-lb-ip"
}

resource "google_compute_global_forwarding_rule" "web_forwarding_rule" {
  name       = "web-forwarding-rule"
  target     = google_compute_target_http_proxy.web_http_proxy.self_link
  port_range = "80"
  ip_protocol = "TCP"
  ip_address = google_compute_global_address.web_lb_ip.address
}

output "load_balancer_ip" {
  description = "HTTP Load Balancer'ın harici IP adresi"
  value       = google_compute_global_address.web_lb_ip.address
}