module "kinesis" {
  source           = "./modules/kinesis"
  shard_count      = 1
  retention_period = 24
  environment      = "dev"
}

module "lambda" {
  source = "./modules/lambda"

  reddit_client_id     = var.reddit_client_id
  reddit_client_secret = var.reddit_client_secret
  reddit_user_agent    = var.reddit_user_agent
  subreddit_name       = var.subreddit_name
  input_stream_name  = module.kinesis.input_stream_name
  input_stream_arn   = module.kinesis.input_stream_arn
  output_stream_arn = module.kinesis.output_stream_arn
}