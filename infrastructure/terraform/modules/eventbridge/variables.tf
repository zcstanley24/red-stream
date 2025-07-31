variable "input_stream_arn" {
  description = "ARN of the Kinesis stream to pull Reddit data from"
  type        = string
}

variable "output_stream_arn" {
  description = "ARN of the Kinesis stream to push Reddit data to"
  type        = string
}