import os
import json
import boto3
import praw
from dotenv import load_dotenv

if os.environ.get('AWS_EXECUTION_ENV') is None:
	load_dotenv()

REDDIT_CLIENT_ID = os.environ['REDDIT_CLIENT_ID']
REDDIT_CLIENT_SECRET = os.environ['REDDIT_CLIENT_SECRET']
REDDIT_USER_AGENT = os.environ.get('REDDIT_USER_AGENT')
SUBREDDIT_NAME = os.environ.get('SUBREDDIT_NAME', 'all')
KINESIS_STREAM_NAME = os.environ['KINESIS_STREAM_NAME']

kinesis_client = boto3.client('kinesis')

reddit = praw.Reddit(
	client_id=REDDIT_CLIENT_ID,
	client_secret=REDDIT_CLIENT_SECRET,
	user_agent=REDDIT_USER_AGENT,
)

def lambda_producer(_event, _context):
	try:
		subreddit = reddit.subreddit(SUBREDDIT_NAME)
		new_submissions = subreddit.new(limit=10)

		records = []

		for submission in new_submissions:
			submission_payload = {
				'id': submission.id,
				'title': submission.title,
				'author': str(submission.author) if submission.author else '[deleted]',
				'created_utc': submission.created_utc,
				'url': submission.url,
				'score': submission.score,
				'num_comments': submission.num_comments,
				'subreddit': submission.subreddit.display_name,
			}
			record = {
				'Data': json.dumps(submission_payload).encode('utf-8'),
				'PartitionKey': submission.subreddit.display_name
			}
			records.append(record)

		if records:
			response = kinesis_client.put_records(
				Records=records,
				StreamName=KINESIS_STREAM_NAME
			)
			print(f"Sent {len(records)} records to Kinesis, FailedCount: {response['FailedRecordCount']}")

		else:
			print("No new submissions found.")
		
		return {
			'statusCode': 200,
			'body': f"Processed {len(records)} Reddit posts"
		}
    
	except Exception as e:
		return {
			'statusCode': 500,
			'body': f"Error processing posts: {str(e)}"
		}