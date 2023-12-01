data "aws_ami" "amzLinux" {
        most_recent = true
        owners = ["amazon"]
    
    filter {
        name = "name"
        values = ["al2023-ami-2023*x86_64"]
        }
}

#Launch Template
resource "aws_launch_template" "dev-launch-template" {
  name = "WebserverLaunchTemplate"
  image_id = data.aws_ami.amzLinux.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg_vpc.id]

 }

#Autoscaling Group
resource "aws_autoscaling_group" "dev-AutoScalingGroup" {
  name                              = "dev-autoscaling-group"
  max_size                          = 4
  min_size                          = 2
  desired_capacity                  = 2
  
  vpc_zone_identifier               = [aws_subnet.public-1.id,aws_subnet.public-2.id]
  target_group_arns                 = [aws_lb_target_group.target-group.arn]
  health_check_type                 = "ELB"
  health_check_grace_period         = 300

  launch_template {
    id                              = aws_launch_template.dev-launch-template.id
    version                         = "$Latest"
  }
}
#Autoscaling policy

resource "aws_autoscaling_policy" "dev_policy" {
  name                              = "CPUpolicy"
  policy_type                       = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type        = "ASGAverageCPUUtilization"
    }
      target_value                  = 75.0
  }
  autoscaling_group_name            = aws_autoscaling_group.dev-AutoScalingGroup.name
}