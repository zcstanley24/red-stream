output "stream_name" {
  description = "The name of the Kinesis stream"
  value       = aws_kinesis_stream.reddit_stream.name
}