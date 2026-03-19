output "gcelab_external_ip" {
  description = "External IP of gcelab"
  value       = google_compute_instance.gcelab.network_interface[0].access_config[0].nat_ip
}

output "nginx_url" {
  description = "NGINX web server URL"
  value       = "http://${google_compute_instance.gcelab.network_interface[0].access_config[0].nat_ip}"
}

output "gcelab2_external_ip" {
  description = "External IP of gcelab2"
  value       = google_compute_instance.gcelab2.network_interface[0].access_config[0].nat_ip
}
