output "input_stream_name" {
  description = "The name of the Kinesis input stream"
  value       = aws_kinesis_stream.reddit_stream.name
}

output "input_stream_arn" {
  description = "The ARN of the Kinesis input stream"
  value       = aws_kinesis_stream.reddit_stream.arn
}

output "output_stream_arn" {
  description = "The ARN of the Kinesis output stream"
  value = aws_kinesis_stream.output_stream.arn
}