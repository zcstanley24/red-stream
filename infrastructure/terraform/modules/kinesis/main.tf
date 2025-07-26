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