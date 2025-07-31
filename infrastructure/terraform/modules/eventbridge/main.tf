provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "eventbridge_pipe_role" {
  name = "eventbridge-pipe-sagemaker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "pipes.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_pipe_policy" {
  name   = "pipe-to-sagemaker-policy"
  role   = aws_iam_role.eventbridge_pipe_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:ListStreams",
          "kinesis:ListShards"
        ],
        Resource = var.input_stream_arn
      },
      {
        Effect = "Allow",
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ],
        Resource = var.output_stream_arn
      },
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_pipes_pipe" "reddit_filtered_to_output_stream" {
  name     = "reddit-filtered-to-output-stream"
  role_arn = aws_iam_role.eventbridge_pipe_role.arn

  source = var.input_stream_arn
  source_parameters {
    kinesis_stream_parameters {
      starting_position = "LATEST"
    }
    filter_criteria {
      filter {
        pattern = jsonencode({
          num_comments = [{ "numeric": [">", 0] }],
          author = [{ "anything-but": "[deleted]" }]
        })
      }
    }
  }

  target = var.output_stream_arn
  target_parameters {
    kinesis_stream_parameters {
      partition_key = "reddit"
    }

    input_template = jsonencode({
      "source": "eventbridge-pipe",
      "id":       "<$.id>",
      "title":    "<$.title>",
      "author":   "<$.author>",
      "created_utc": "<$.created_utc>",
      "url":        "<$.url>",
      "score":      "<$.score>",
      "num_comments": "<$.num_comments>",
      "subreddit":  "<$.subreddit>"
    })
  }

  depends_on = [aws_iam_role_policy.eventbridge_pipe_policy]
}

resource "aws_iam_role" "sagemaker_execution_role" {
  name = "sagemaker-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "sagemaker.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_basic_execution" {
  role       = aws_iam_role.sagemaker_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_sagemaker_model" "sentiment_model" {
  name               = "reddit-sentiment-model"
  execution_role_arn = aws_iam_role.sagemaker_execution_role.arn

  primary_container {
    image = "763104351884.dkr.ecr.us-east-1.amazonaws.com/huggingface-pytorch-inference:2.1.0-transformers4.37.0-cpu-py310-ubuntu22.04"
    mode  = "SingleModel"

    environment = {
      HF_TASK            = "text-classification"
      HF_MODEL_ID        = "distilbert-base-uncased-finetuned-sst-2-english"
      SAGEMAKER_PROGRAM  = "inference.py"
      SAGEMAKER_REGION   = "us-east-1"
    }
  }
}

resource "aws_sagemaker_endpoint_configuration" "sentiment_config" {
  name = "reddit-sentiment-config"

  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.sentiment_model.name
    serverless_config {
      memory_size_in_mb = 1024
      max_concurrency   = 1
    }
  }
}

resource "aws_sagemaker_endpoint" "sentiment_endpoint" {
  name                 = "reddit-sentiment-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.sentiment_config.name
}