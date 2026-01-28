resource "aws_cloudwatch_log_group" "api" {
  name              = "/starttech/api"
  retention_in_days = 7
}
