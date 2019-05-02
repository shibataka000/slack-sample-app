terraform {
  backend "s3" {
    bucket = "sbtk-tfstate"
    key = "slack-sample-app/slack-sample-app.tf"
    region = "ap-northeast-1"
  }
}

provider "aws" {
  region = "${var.region}"
  profile = "${var.profile}"
}

resource "aws_lambda_function" "main" {
  function_name = "${var.prefix}"
  filename = "${var.lambda_filename}"
  source_code_hash = "${base64sha256(file("${var.lambda_filename}"))}"
  handler = "${var.lambda_handler}"
  runtime = "python3.6"
  timeout = "300"
  memory_size = "1024"
  role = "${aws_iam_role.lambda.arn}"
}

resource "aws_api_gateway_rest_api" "main" {
  name = "${var.prefix}"
}

resource "aws_api_gateway_method" "main" {
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  resource_id = "${aws_api_gateway_rest_api.main.root_resource_id}"
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "main" {
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  resource_id = "${aws_api_gateway_method.main.resource_id}"
  http_method = "${aws_api_gateway_method.main.http_method}"
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${aws_lambda_function.main.invoke_arn}"
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  stage_name = "prod"
  depends_on = [
    "aws_api_gateway_integration.main"
  ]
}

resource "aws_lambda_permission" "main" {
  statement_id = "${var.prefix}-lambda-permission"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.main.arn}"
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_deployment.main.execution_arn}/*/"
}

resource "aws_api_gateway_domain_name" "main" {
  domain_name = "${var.api_gateway_domain_name}"
  certificate_arn = "${var.acm_certificate_arn}"
}

resource "aws_api_gateway_base_path_mapping" "main" {
  api_id = "${aws_api_gateway_rest_api.main.id}"
  stage_name = "${aws_api_gateway_deployment.main.stage_name}"
  domain_name = "${aws_api_gateway_domain_name.main.domain_name}"
}

resource "aws_iam_role" "lambda" {
  name = "${var.prefix}-lambda-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "lambda" {
  name = "${var.prefix}-policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role = "${aws_iam_role.lambda.name}"
  policy_arn = "${aws_iam_policy.lambda.arn}"
}

resource "aws_route53_record" "api_gateway" {
  zone_id = "${var.route53_zone_id}"
  name = "${var.api_gateway_domain_name}"
  type = "A"
  alias {
    name = "${aws_api_gateway_domain_name.main.cloudfront_domain_name}"
    zone_id = "${aws_api_gateway_domain_name.main.cloudfront_zone_id}"
    evaluate_target_health = true
  }
}
