variable "reddit_client_id" {
  description = "The client ID for authenticating with the Reddit API"
  type        = string
}

variable "reddit_client_secret" {
  description = "The client secret for authenticating with the Reddit API"
  type        = string
}

variable "reddit_user_agent" {
  description = "The user agent string required by Reddit API requests"
  type        = string
}

variable "input_stream_name" {
  description = "Name of the Kinesis stream to push Reddit data to"
  type        = string
}

variable "input_stream_arn" {
  description = "ARN of the Kinesis stream to push Reddit data to"
  type        = string
}

variable "output_stream_name" {
  description = "Name of the Kinesis stream to push filtered Reddit data to"
  type        = string
}

variable "sagemaker_endpoint_name" {
  description = "Name of the SageMaker endpoint to send Reddit data for sentiment analysis"
  type        = string
}