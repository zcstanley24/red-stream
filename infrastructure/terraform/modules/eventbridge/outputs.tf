output "sagemaker_endpoint_name" {
  description = "Name of the SageMaker endpoint to send Reddit data for sentiment analysis"
  value = aws_sagemaker_endpoint.sentiment_endpoint.name
}