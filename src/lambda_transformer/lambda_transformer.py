import base64
import json
import boto3
import os
from dotenv import load_dotenv

if os.environ.get('AWS_EXECUTION_ENV') is None:
	load_dotenv()

SAGEMAKER_ENDPOINT_NAME = os.environ["SAGEMAKER_ENDPOINT_NAME"]
OUTPUT_STREAM_NAME = os.environ["OUTPUT_STREAM_NAME"]

kinesis_client = boto3.client('kinesis')
runtime = boto3.client("sagemaker-runtime")

def lambda_handler(event, context):
  for record in event["Records"]:
    try:
      raw_data = base64.b64decode(record["kinesis"]["data"])
      payload = json.loads(raw_data)
      title = payload.get("title")
      if not title:
         continue
      
      body = json.dumps({ "inputs": title})

      response = runtime.invoke_endpoint(
        EndpointName=SAGEMAKER_ENDPOINT_NAME,
        ContentType="application/json",
        Body=body
      )

      result = json.loads(response["Body"].read().decode("utf-8"))
      result_payload = result[0] if isinstance(result, list) and result else {}

      output = {
        "id": payload.get("id", "N/A"),
        "title": title,
        "sentiment": result_payload.get("label", "unknown").lower(),
        "confidence": result_payload.get("score", 0),
        "source": "lambda-sagemaker"
      }

      kinesis_client.put_record(
        StreamName=OUTPUT_STREAM_NAME,
        PartitionKey="partition-key",
        Data=json.dumps(output)
      )

    except Exception as e:
      print(f"Record failed to process: {e}")

  return {
    "statusCode": 200,
    "body": json.dumps("Processed batch successfully.")
  }