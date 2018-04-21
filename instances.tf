provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "aws_instance" "master" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  subnet_id = "${aws_subnet.public.id}"
  security_groups = ["${aws_security_group.local_all.id}", "${aws_security_group.ssh_access.id}", "${aws_security_group.out_access.id}"]
  key_name = "${aws_key_pair.ssh_deploy.key_name}"
}

resource "aws_instance" "slave1" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  subnet_id = "${aws_subnet.public.id}"
  security_groups = ["${aws_security_group.local_all.id}", "${aws_security_group.ssh_access.id}", "${aws_security_group.out_access.id}"]
  key_name = "${aws_key_pair.ssh_deploy.key_name}"
}

resource "aws_instance" "graphite" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  subnet_id = "${aws_subnet.public.id}"
  security_groups = ["${aws_security_group.local_all.id}", "${aws_security_group.ssh_access.id}", "${aws_security_group.out_access.id}"]
  key_name = "${aws_key_pair.ssh_deploy.key_name}"
  user_data = "${file("resources/docker-install.sh")}"
}

resource "aws_eip" "one" {
  instance = "${aws_instance.master.id}"
}

resource "aws_eip" "two" {
  instance = "${aws_instance.slave1.id}"
}

resource "aws_eip" "three" {
  instance = "${aws_instance.graphite.id}"
}

output "public_ip_1" {
  value = "${aws_eip.one.public_ip}"
}

output "public_ip_2" {
  value = "${aws_eip.two.public_ip}"
}

output "public_ip_3" {
  value = "${aws_eip.three.public_ip}"
}
