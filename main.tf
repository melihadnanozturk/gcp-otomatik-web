provider "google" {
  project = var.project_id
  region  = "europe-west4"
}

variable "project_id" {
  default = "sistemyon-odev"
}

resource "google_service_account" "vm1_sa" {
  account_id = "vm1-sa"
  display_name = "VM1 Service Account"
}

resource "google_compute_instance" "webserver_vm" {
  name         = "sistem-yon-odev-vm"
  machine_type = "e2-micro"
  zone         = "europe-west4-a"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.public_ssh_key_path)}"
    startup-script = <<-EOT
      #!/bin/bash
      wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy
      chmod +x cloud_sql_proxy
      ./cloud_sql_proxy -dir=/cloudsql -instances=${var.project_id}:europe-west4:odev-postgres &
    EOT
  }

  service_account {
    email = google_service_account.vm1_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["webserver", "ssh", "http", "lb-backend"]
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
    access_config {}

  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.public_ssh_key_path)}"
  }

  tags = ["webserver", "ssh","http", "lb-backend"]
}

output "vm1_external_ip" {
  description = "VM1'in dış IP adresi"
  value       = google_compute_instance.webserver_vm.network_interface[0].access_config[0].nat_ip
}

output "vm2_external_ip" {
  description = "VM2'nin dış IP adresi"
  value       = google_compute_instance.webserver_vm_2.network_interface[0].access_config[0].nat_ip
}


variable "ssh_username" {
  description = "VM'ye bağlanacak SSH kullanıcı adı."
  type        = string
  default     = "adnan@white-takke-home"
}

variable "public_ssh_key_path" {
  description = "SSH anahtar dosya yolu "
  type        = string
  default     = "~/Desktop/project/ssh.pub"
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

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  source_ranges = ["10.128.0.0/9"] # GCP default VPC iç IP aralığı
  target_tags   = ["webserver"]
}

resource "google_compute_firewall" "allow_internal_app" {
  name    = "allow-internal-app"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }
  source_tags   = ["webserver"]
  target_tags   = ["webserver"]
  source_ranges = ["10.128.0.0/9"]
}

resource "google_compute_firewall" "allow_lb_http" {
  name    = "allow-lb-http"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # Google LB IP aralıkları
  target_tags   = ["lb-backend"]
}

resource "google_compute_firewall" "allow_internal_backend" {
  name    = "allow-internal-backend"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }
  source_tags = ["lb-backend"]
  target_tags = ["lb-backend"]
}

resource "google_compute_firewall" "allow_ssh_only_vm1" {
  name    = "allow-ssh-only-vm1"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

resource "google_sql_database_instance" "postgres_instance" {
  name             = "odev-postgres"
  database_version = "POSTGRES_15"
  region           = "europe-west4"
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = "projects/${var.project_id}/global/networks/default"
    }
  }
}

resource "google_sql_database" "app_db" {
  name     = "appdb"
  instance = google_sql_database_instance.postgres_instance.name
}

resource "google_sql_user" "app_user" {
  name     = "appuser"
  instance = google_sql_database_instance.postgres_instance.name
  password = "testUser123"
}

resource "google_project_iam_member" "vm1_sql_client" {
  project = var.project_id
  role = "roles/cloudsql.client"
  member = "serviceAccount:${google_compute_instance.webserver_vm.service_account[0].email}"
}