import base64
import json
import boto3
import os
from dotenv import load_dotenv

if os.environ.get('AWS_EXECUTION_ENV') is None:
	load_dotenv()

firehose = boto3.client("firehose")
OUTPUT_STREAM_NAME = os.environ["OUTPUT_STREAM_NAME"]

def lambda_handler(event, context):
  filteredCount = 0
  for record in event["Records"]:
    try:
      payload = base64.b64decode(record["kinesis"]["data"])
      post = json.loads(payload)

      if post.get("num_comments", 0) > 0:
        firehose.put_record(
          DeliveryStreamName=OUTPUT_STREAM_NAME,
          Record={
            "Data": (json.dumps(post) + "\n").encode("utf-8")
          }
        )
        filteredCount += 1
    except Exception as e:
      print(f"Record failed to process: {e}")
      continue

  return {
    "statusCode": 200,
    "body": f"Processed {len(event['Records'])} records. Sent {filteredCount} to Firehose."
  }