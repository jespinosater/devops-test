resource "aws_security_group" "local_all" {
  name = "local_all"
  description = "Allow all local traffic"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }
}

resource "aws_security_group" "ssh_access" {
  name = "ssh_access"
  description = "Allow access to SSH"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.allowed_ip}"]
  }
}

resource "aws_security_group" "out_access" {
  name = "out_access"
  description = "Allow all outbound traffic"
  vpc_id = "${aws_vpc.main.id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
