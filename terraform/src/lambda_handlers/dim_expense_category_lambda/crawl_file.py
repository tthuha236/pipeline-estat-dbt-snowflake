import requests
import json
import boto3
from datetime import datetime

s3 = boto3.client('s3')

def lambda_handler(event, context):
    if not event['href']:
        return {"status": 400, "body": json.dumps("Cannot get the base url and href from event")}
    file_url = event['href']
    try:
        response = requests.get(file_url)
        if response.status_code == 200:
            # place excel file into s3 bucket
            filename = 'expense_category_' + datetime.now().strftime('%Y%m%d') + '.xlsx'
            s3.put_object(
                Bucket=event['target_bucket'],
                Key=event['target_folder'] + '/' + filename,
                Body=response.content
            )
            return {
                "status":200,
                "output_file":filename,
                "body":json.dumps(f"{filename} was successfully donwloaded"),
                "function_name": context.function_name
            }
        else:
            print(f"Failed to download file. Status code: {response.status_code}")
    except Exception as e:
        print("Job failed: ",str(e))
        return {"status": 500, "body": json.dumps(f"Job failed: {str(e)}")}