#!/bin/bash
set -a
source .env
set +a

export TF_VAR_reddit_client_id="$REDDIT_CLIENT_ID"
export TF_VAR_reddit_client_secret="$REDDIT_CLIENT_SECRET"
export TF_VAR_reddit_user_agent="$REDDIT_USER_AGENT"
export TF_VAR_subreddit_name="$SUBREDDIT_NAME"

cd infrastructure/terraform

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 plan|apply"
  exit 1
fi

if [ "$1" = "plan" ]; then
  terraform init
  terraform plan
  read -p "Press ENTER to exit..."
elif [ "$1" = "apply" ]; then
  terraform init
  terraform apply
else
  echo "Invalid argument: $1"
  echo "Usage: $0 plan|apply"
  exit 1
fi