provider "aws" {
  region = "us-east-1"
}

resource "aws_kinesis_stream" "reddit_stream" {
  name             = "reddit-input-stream"
  shard_count      = var.shard_count
  retention_period = var.retention_period
  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "firehose_bucket" {
  bucket = "firehose-output-bucket-reddit-072625"
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
  name        = "reddit-output-stream"
  shard_count = 1
  retention_period = 24
  tags = {
    Environment = var.environment
  }
}

resource "aws_kinesis_firehose_delivery_stream" "reddit_firehose" {
  name        = "reddit-output-firehose"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.output_stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    bucket_arn         = aws_s3_bucket.firehose_bucket.arn
    buffering_interval = 60
    buffering_size     = 5
    compression_format = "UNCOMPRESSED"
  }
}