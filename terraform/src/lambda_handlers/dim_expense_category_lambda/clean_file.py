import json
import pandas as pd
import boto3
import io

s3 = boto3.client('s3')
def lambda_handler(event, context):
    bucket = event["s3_bucket"]
    raw_folder = event["raw_folder"]
    clean_folder = event["clean_folder"]
    file_name = event["file_name"]
    raw_file_path = f'{raw_folder}/{file_name}'
    clean_file_path = f"{clean_folder}/{file_name.replace('.xlsx','.csv')}"
    
    try:
        # get file from s3 bucket
        response = s3.get_object(Bucket=bucket, Key=raw_file_path)
        content = response['Body'].read()
        df = pd.read_excel(io.BytesIO(content), skiprows=8, sheet_name="2消費支出", dtype = str)
        # drop not used columns and rows
        df = df.iloc[:,[3,4,5,6,14]]
        df.columns = ["category_cd","main_category_name","sub_category_name","detailed_category_name","description"]
        df = df.dropna(subset=["category_cd"])
        df = df[df.category_cd.str.match(r"^\d+")]

        # fill in the main_category_name and sub_category_name
        df["main_category_cd"] = df["category_cd"].apply(lambda x: None if len(x.split("."))<2 else x.split(".")[0])
        df["sub_category_cd"] = df["category_cd"].apply(lambda x: None if len(x.split("."))<3 else ".".join(x.split(".")[0:2]))
        main_category_map = df.set_index("category_cd")["main_category_name"].dropna()
        df["main_category_name"] = df.apply(lambda row:main_category_map[row["main_category_cd"]] \
                                                                if pd.isnull(row["main_category_name"]) and not pd.isnull(row["main_category_cd"]) \
                                                                else row["main_category_name"],
                                                                axis=1)

        sub_category_map = df.set_index("category_cd")["sub_category_name"].dropna()
        df["sub_category_name"] = df.apply(lambda row:sub_category_map[row["sub_category_cd"]] \
                                                                if pd.isnull(row["sub_category_name"]) and not pd.isnull(row["sub_category_cd"]) \
                                                                else row["sub_category_name"],
                                                                axis=1)
        df=df[["category_cd","main_category_name","sub_category_name","detailed_category_name","description"]]

        # save table as csv file in s3 bucket
        csv_buffer = io.StringIO()
        df.to_csv(csv_buffer, index=False)
        s3.put_object(Bucket=bucket, 
                      Key=clean_file_path, 
                      Body=csv_buffer.getvalue())
        return {
            'status': 200,
            'body': json.dumps('Clean file successfully'),
            'output_file': clean_file_path,
            'function_name': context.function_name
        }

    except Exception as e:
        return {
        'status': 500,
        'body': json.dumps('Error cleaning file: ' + raw_file_path + str(e))
    }