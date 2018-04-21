resource "null_resource" "docker_graphite" {
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      host = "${aws_eip.three.public_ip}"
      user = "${var.remote_username}"
      private_key = "${data.local_file.private_ssh_key.content}"
    }

    inline = [
      "while [ ! -f /tmp/docker_installed ]; do sleep 5; done",
      "docker run -d --name graphite --restart=always -p 80:80 -p 2003-2004:2003-2004 -p 2023-2024:2023-2024 -p 8125:8125/udp -p 8126:8126 graphiteapp/graphite-statsd",
      "docker run --network=\"host\" -d -p 3000:3000 grafana/grafana"
    ]
  }
  depends_on = ["aws_instance.graphite"]
}
