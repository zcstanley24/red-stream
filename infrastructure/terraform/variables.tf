variable "reddit_client_id" {
  type        = string
  description = "Reddit API client ID"
}

variable "reddit_client_secret" {
  type        = string
  description = "Reddit API client secret"
}

variable "reddit_user_agent" {
  type        = string
  description = "User agent for Reddit API"
}

variable "subreddit_name" {
  type        = string
  description = "Subreddit to pull data from"
  default     = "all"
}