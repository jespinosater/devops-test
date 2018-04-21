resource "null_resource" "ssh_key" {
  provisioner "local-exec" {
    command = "ssh-keygen -t rsa -b 4096 -C \"Test AWS key\" -P '' -f ssh/test_key"
  }

  provisioner "local-exec" {
    command = "chmod 400 ssh/test_key"
  }
  provisioner "local-exec" {
    command = "rm -f ssh/test_key*"
    when = "destroy"
  }
}

data "local_file" "public_ssh_key" {
  filename = "ssh/test_key.pub"
  depends_on = ["null_resource.ssh_key"]
}

data "local_file" "private_ssh_key" {
  filename = "ssh/test_key"
  depends_on = ["null_resource.ssh_key"]
}

resource "aws_key_pair" "ssh_deploy" {
  key_name = "test_key"
  public_key = "${data.local_file.public_ssh_key.content}"
  depends_on = ["null_resource.ssh_key"]
}
