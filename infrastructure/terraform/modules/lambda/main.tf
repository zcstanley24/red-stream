resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_kinesis_policy" {
  name = "lambda-kinesis-access"
  role = aws_iam_role.lambda_exec_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "kinesis:PutRecord",
        "kinesis:PutRecords"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_lambda_function" "lambda_producer" {
  function_name = "lambda_producer"
  filename      = "${path.module}/build/lambda_producer_payload.zip"
  handler       = "lambda_producer.lambda_producer"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  timeout       = 30
  memory_size   = 128

  environment {
    variables = {
      REDDIT_CLIENT_ID     = var.reddit_client_id
      REDDIT_CLIENT_SECRET = var.reddit_client_secret
      REDDIT_USER_AGENT    = var.reddit_user_agent
      SUBREDDIT_NAME       = var.subreddit_name
      KINESIS_STREAM_NAME  = var.kinesis_stream_name
    }
  }

  tags = {
    Environment = "dev"
  }

  depends_on = [
    aws_iam_role.lambda_exec_role,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy.lambda_kinesis_policy
  ]
}