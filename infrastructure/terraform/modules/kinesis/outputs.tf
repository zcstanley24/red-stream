output "input_stream_name" {
  description = "The name of the Kinesis input stream"
  value       = aws_kinesis_stream.reddit_stream.name
}

output "input_stream_arn" {
  description = "The ARN of the Kinesis input stream"
  value       = aws_kinesis_stream.reddit_stream.arn
}

output "output_stream_name" {
  description = "The name of the Kinesis output stream"
  value       = aws_kinesis_stream.output_stream.name
}

output "output_stream_arn" {
  description = "The ARN of the Kinesis output stream"
  value       = aws_kinesis_stream.output_stream.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket with processed and partitioned reddit data"
  value       = aws_s3_bucket.firehose_bucket.bucket
}