locals {
  uuid = "${uuid()}"
}

data "local_file" "netdata_install" {
  filename = "resources/kickstart-static64.sh"
}

resource "null_resource" "netdata_master" {
  provisioner "file" {
    connection {
      type = "ssh"
      host = "${aws_eip.one.public_ip}"
      user = "${var.remote_username}"
      private_key = "${data.local_file.private_ssh_key.content}"
    }

    source = "${data.local_file.netdata_install.filename}"
    destination = "/tmp/kickstart-static64.sh"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      host = "${aws_eip.one.public_ip}"
      user = "${var.remote_username}"
      private_key = "${data.local_file.private_ssh_key.content}"
    }

    inline = [
      "chmod +x /tmp/kickstart-static64.sh",
      "/tmp/kickstart-static64.sh --dont-wait",
      "sudo systemctl stop netdata",
      "echo \"[${local.uuid}]\" | sudo tee /opt/netdata/netdata-configs/stream.conf",
      "echo \"    enabled = yes\" | sudo tee --append /opt/netdata/netdata-configs/stream.conf",

      "echo \"[backend]\" | sudo tee --append /opt/netdata/netdata-configs/netdata.conf",
      "echo \"    enabled = yes\" | sudo tee --append /opt/netdata/netdata-configs/netdata.conf",
      "echo \"    data source = average\" | sudo tee --append /opt/netdata/netdata-configs/netdata.conf",
      "echo \"    type = graphite\" | sudo tee --append /opt/netdata/netdata-configs/netdata.conf",
      "echo \"    destination = ${aws_instance.graphite.private_ip}\" | sudo tee --append /opt/netdata/netdata-configs/netdata.conf",
      "echo \"    prefix = netdata\" | sudo tee --append /opt/netdata/netdata-configs/netdata.conf",
      "echo \"    hostname = ip-172-31-0-241\" | sudo tee --append /opt/netdata/netdata-configs/netdata.conf",
      "echo \"    update every = 10\" | sudo tee --append /opt/netdata/netdata-configs/netdata.conf",
      "echo \"    buffer on failures = 10\" | sudo tee --append /opt/netdata/netdata-configs/netdata.conf",
      "echo \"    timeout ms = 20000\" | sudo tee --append /opt/netdata/netdata-configs/netdata.conf",
      "echo \"    send names instead of ids = yes\" | sudo tee --append /opt/netdata/netdata-configs/netdata.conf",
      "echo \"    send charts matching = *\" | sudo tee --append /opt/netdata/netdata-configs/netdata.conf",
      "echo \"    send hosts matching = *\" | sudo tee --append /opt/netdata/netdata-configs/netdata.conf",
      "sudo systemctl start netdata"
    ]
  }
  depends_on = ["aws_instance.master"]
}

resource "null_resource" "netdata_slave1" {
  provisioner "file" {
    connection {
      type = "ssh"
      host = "${aws_eip.two.public_ip}"
      user = "${var.remote_username}"
      private_key = "${data.local_file.private_ssh_key.content}"
    }

    source = "${data.local_file.netdata_install.filename}"
    destination = "/tmp/kickstart-static64.sh"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      host = "${aws_eip.two.public_ip}"
      user = "${var.remote_username}"
      private_key = "${data.local_file.private_ssh_key.content}"
    }

    inline = [
      "chmod +x /tmp/kickstart-static64.sh",
      "/tmp/kickstart-static64.sh --dont-wait",
      "sudo systemctl stop netdata",
      "echo \"[stream]\" | sudo tee /opt/netdata/netdata-configs/stream.conf",
      "echo \"    enabled = yes\" | sudo tee --append /opt/netdata/netdata-configs/stream.conf",
      "echo \"    destination = ${aws_instance.master.private_ip}\" | sudo tee --append /opt/netdata/netdata-configs/stream.conf",
      "echo \"    api key= ${local.uuid}\" | sudo tee --append /opt/netdata/netdata-configs/stream.conf",
      "sudo systemctl start netdata"
    ]
  }
  depends_on = ["aws_instance.slave1"]
}

