locals {
	ssh_key_public  = "$HOME/.ssh/id_rsa.pub"
	ssh_key_private = "$HOME/.ssh/id_rsa"
	ssh_key_name	= "test"
	domain_name		= "example.com"
	script			= "./install.sh"
}

# ----------------------------------------------
# Provider
# ----------------------------------------------

provider "digitalocean" {
	token = ""
}

# ----------------------------------------------
# Hardware
# ----------------------------------------------

resource "digitalocean_droplet" "web" {
	image	= "40707000"
	name	 = "web-1"
	region = "sgp1"
	size	 = "1gb"
	ssh_keys = [ "${digitalocean_ssh_key.default.fingerprint}" ]
}

# ----------------------------------------------
# Records
# ----------------------------------------------

resource "digitalocean_domain" "default" {
	name		= "${local.domain_name}"
	ip_address = "${digitalocean_droplet.web.ipv4_address}"
}

resource "digitalocean_record" "a_record" {
	depends_on	= [ "digitalocean_domain.default" ]
	type		= "A"
	domain		= "${local.domain_name}"
	value		= "${digitalocean_droplet.web.ipv4_address}"
	name		= "@"
}

resource "digitalocean_record" "a_record_www" {
	depends_on	= [ "digitalocean_domain.default", "digitalocean_record.a_record" ]
	type		= "A"
	domain		= "${local.domain_name}"
	value		= "${digitalocean_droplet.web.ipv4_address}"
	name		= "www"
	provisioner "remote-exec" {
		script = "${local.script}"
		connection {
			host = "${digitalocean_droplet.web.ipv4_address}"
			user = "root"
			type = "ssh"
			timeout = "20s"
			private_key = "${file(local.ssh_key_private)}"
		}
	}
}

# ----------------------------------------------
# Script
# ----------------------------------------------

resource "digitalocean_ssh_key" "default" {
	name		= "Terraform Example"
	public_key 	= "${file(local.ssh_key_public)}"
}
