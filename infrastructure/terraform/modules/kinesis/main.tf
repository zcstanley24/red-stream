provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

resource "aws_kinesis_stream" "reddit_stream" {
  name             = "reddit-input-stream"
  shard_count      = 1
  retention_period = 24
}

resource "aws_s3_bucket" "firehose_bucket" {
  bucket = "firehose-output-bucket-reddit-${data.aws_caller_identity.current.account_id}"
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_delivery_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "firehose.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "firehose_policy" {
  name = "firehose_s3_policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.firehose_bucket.arn,
          "${aws_s3_bucket.firehose_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords"
        ],
        Resource = aws_kinesis_stream.output_stream.arn
      }
    ]
  })
}

resource "aws_kinesis_stream" "output_stream" {
  name             = "reddit-output-stream"
  shard_count      = 1
  retention_period = 24
}

resource "aws_kinesis_firehose_delivery_stream" "reddit_firehose" {
  name        = "reddit-output-firehose"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.output_stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose_role.arn
    bucket_arn          = aws_s3_bucket.firehose_bucket.arn
    buffering_interval  = 60
    buffering_size      = 64
    compression_format  = "UNCOMPRESSED"
    prefix              = "source=!{partitionKeyFromQuery:source}/"
    error_output_prefix = "errors/"

    dynamic_partitioning_configuration {
      enabled = true
    }
    
    processing_configuration {
      enabled = true
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{source:.source}"
        }
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
      }
    }
  }
}