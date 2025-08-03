module "kinesis" {
  source           = "./modules/kinesis"
}

module "lambda" {
  source = "./modules/lambda"

  reddit_client_id     = var.reddit_client_id
  reddit_client_secret = var.reddit_client_secret
  reddit_user_agent    = var.reddit_user_agent
  input_stream_name  = module.kinesis.input_stream_name
  input_stream_arn   = module.kinesis.input_stream_arn
  output_stream_name = module.kinesis.output_stream_name
  sagemaker_endpoint_name = module.eventbridge.sagemaker_endpoint_name
}

module "eventbridge" {
  source = "./modules/eventbridge"

  input_stream_arn   = module.kinesis.input_stream_arn
  output_stream_arn   = module.kinesis.output_stream_arn
}

module "athena" {
  source = "./modules/athena"

  s3_bucket_name    = module.kinesis.s3_bucket_name
}