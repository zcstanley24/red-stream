provider "aws" {
  region = "us-east-1"
}

resource "aws_kinesis_stream" "reddit_stream" {
  name             = "reddit-data-stream"
  shard_count      = var.shard_count
  retention_period = var.retention_period
  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role" "kda_role" {
  name = "kda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "kinesisanalytics.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "kda_policy" {
  name = "kda_policy"
  role = aws_iam_role.kda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords"
        ],
        Resource = aws_kinesis_stream.reddit_stream.arn
      }
    ]
  })
}

resource "aws_kinesisanalyticsv2_application" "reddit_analytics" {
  name        = "reddit-analytics-app"
  runtime_environment    = "SQL-1_0"
  service_execution_role = aws_iam_role.kda_role.arn

  application_configuration {
    sql_application_configuration {
      inputs {
        name_prefix = "reddit_input"
        kinesis_stream_input {
          resource_arn = aws_kinesis_stream.reddit_stream.arn
          role_arn     = aws_iam_role.kda_role.arn
        }

        input_schema {
          record_format {
            record_format_type = "JSON"
          }
          record_columns {
            name     = "id"
            sql_type = "VARCHAR(64)"
            mapping  = "$.id"
          }
          record_columns {
            name     = "title"
            sql_type = "VARCHAR(256)"
            mapping  = "$.title"
          }
          record_columns {
            name     = "author"
            sql_type = "VARCHAR(64)"
            mapping  = "$.author"
          }
          record_columns {
            name     = "created_utc"
            sql_type = "BIGINT"
            mapping  = "$.created_utc"
          }
          record_columns {
            name     = "url"
            sql_type = "VARCHAR(512)"
            mapping  = "$.url"
          }
          record_columns {
            name     = "score"
            sql_type = "INTEGER"
            mapping  = "$.score"
          }
          record_columns {
            name     = "num_comments"
            sql_type = "INTEGER"
            mapping  = "$.num_comments"
          }
          record_columns {
            name     = "subreddit"
            sql_type = "VARCHAR(64)"
            mapping  = "$.subreddit"
          }

          record_format {
            record_format_type = "JSON"
          }
        }
      }
    }
  }
}

resource "aws_kinesis_stream" "kda_output_stream" {
  name        = "reddit-kda-output-stream"
  shard_count = 1
  retention_period = 24
  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "firehose_bucket" {
  bucket = "firehose-output-bucket-reddit-072625"
}

resource "aws_s3_bucket_acl" "firehose_bucket_acl" {
  bucket = aws_s3_bucket.firehose_bucket.id
  acl    = "private"
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
        ]
        Resource = aws_kinesis_stream.kda_output_stream.arn
      }
    ]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "reddit_firehose" {
  name        = "reddit-kda-firehose"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.kda_output_stream.arn
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