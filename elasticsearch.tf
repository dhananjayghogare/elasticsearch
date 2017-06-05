resource "aws_security_group" "elasticsearch" {
  name = "elasticsearch-sg"
  description = "ElasticSearch Security Group"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 9200
    to_port   = 9400
    protocol  = "tcp"
    security_groups = ["${aws_security_group.elasticsearch_elb.id}"]
  }

  ingress {
    from_port = 9200
    to_port   = 9400
    protocol  = "tcp"
    security_groups = ["${aws_security_group.node.id}"]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "ElasticSearch Node"
  }
}


resource "aws_security_group" "elasticsearch_elb" {
  name = "elasticsearch-elb-sg"
  description = "ElasticSearch Elastic Load Balancer Security Group"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 9200
    to_port   = 9200
    protocol  = "tcp"
    security_groups = ["${aws_security_group.node.id}"]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "ElasticSearch Load Balancer"
  }
}

resource "aws_elb" "elasticsearch_elb" {
  name = "elasticsearch-elb"
  subnets = ["${aws_subnet.primary-private.id}","${aws_subnet.secondary-private.id}","${aws_subnet.tertiary-private.id}"]
  security_groups = ["${aws_security_group.elasticsearch_elb.id}"]
  cross_zone_load_balancing = true
  connection_draining = true
  internal = true

  listener {
    instance_port      = 9200
    instance_protocol  = "tcp"
    lb_port            = 9200
    lb_protocol        = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    target              = "TCP:9200"
    timeout             = 5
  }
}

resource "aws_autoscaling_group" "elasticsearch_autoscale_group" {
  name = "elasticsearch-autoscale-group"
  availability_zones = ["${aws_subnet.primary-private.availability_zone}","${aws_subnet.secondary-private.availability_zone}","${aws_subnet.tertiary-private.availability_zone}"]
  vpc_zone_identifier = ["${aws_subnet.primary-private.id}","${aws_subnet.secondary-private.id}","${aws_subnet.tertiary-private.id}"]
  launch_configuration = "${aws_launch_configuration.elasticsearch_launch_config.id}"
  min_size = 3
  max_size = 100
  desired = 3
  health_check_grace_period = "900"
  health_check_type = "EC2"
  load_balancers = ["${aws_elb.elasticsearch_elb.name}"]

  tag {
    key = "Name"
    value = "elasticsearch"
    propagate_at_launch = true
  }

  tag {
    key = "role"
    value = "elasticsearch"
    propagate_at_launch = true
  }

  tag {
    key = "elb_name"
    value = "${aws_elb.elasticsearch_elb.name}"
    propagate_at_launch = true
  }

  tag {
    key = "elb_region"
    value = "${var.aws_region}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "elasticsearch_launch_config" {
  image_id = "${var.elasticsearch_ami_id}"
  instance_type = "${var.elasticsearch_instance_type}"
  iam_instance_profile = "app-server"
  key_name = "${aws_key_pair.terraform.key_name}"
  security_groups = ["${aws_security_group.elasticsearch.id}","${aws_security_group.node.id}"]
  enable_monitoring = false

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = "${var.elasticsearch_volume_size}"
  }
}

