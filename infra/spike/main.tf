data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/build/handler.zip"
}

resource "aws_iam_role" "lambda" {
  name = "sso-elevator-cli-spike-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "spike" {
  function_name    = "sso-elevator-cli-spike"
  role             = aws_iam_role.lambda.arn
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  handler          = "handler.handler"
  runtime          = "python3.12"
  timeout          = 10
}

resource "aws_apigatewayv2_api" "spike" {
  name          = "sso-elevator-cli-spike"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "spike" {
  api_id                 = aws_apigatewayv2_api.spike.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.spike.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "spike" {
  api_id             = aws_apigatewayv2_api.spike.id
  route_key          = "POST /spike"
  target             = "integrations/${aws_apigatewayv2_integration.spike.id}"
  authorization_type = "AWS_IAM"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.spike.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.spike.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.spike.execution_arn}/*/*"
}

output "invoke_url" {
  description = "POST this URL with SigV4 (service=execute-api). Caller needs execute-api:Invoke."
  value       = "${aws_apigatewayv2_api.spike.api_endpoint}/spike"
}
