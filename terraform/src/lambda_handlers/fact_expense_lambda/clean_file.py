import json
import pandas as pd
import re
import boto3
import io
import xlrd

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

        df = pd.read_excel(io.BytesIO(content), skiprows=8, sheet_name="勤労", dtype={
        "分類コード": str})
        print(df.shape)
        # only keep rows that have detailed expense 
        category_cd_pattern = r"^(?!00000)\d+"
        filtered_df = df[df["分類コード"].astype(str).str.match(category_cd_pattern, na=False)]

        # dimension columns & fact columns
        dim_cols = ["時間軸コード", "分類コード"]
        fact_col_pattern = r"\d{5} .+"
        fact_cols = [col for col in filtered_df.columns if re.match(fact_col_pattern, col)]

        # melt table from wide to long
        # each row will represent expense of a city at a certain time
        expense_fact_df = pd.melt(filtered_df, id_vars=dim_cols, value_vars=fact_cols, var_name="地域", value_name="金額")

        # get the area code from area column
        expense_fact_df["地域コード"] = expense_fact_df["地域"].apply(lambda x: x.split(" ")[0])

        # add year and month column
        expense_fact_df["年"] = expense_fact_df["時間軸コード"].apply(lambda x: int(str(x)[0:4]))
        expense_fact_df["月"] = expense_fact_df["時間軸コード"].apply(lambda x: int(str(x)[-2:]))

        # drop unnessary column
        expense_fact_df = expense_fact_df.drop(["地域","時間軸コード" ], axis = 1)

        # save table as csv file in s3 bucket
        csv_buffer = io.StringIO()
        expense_fact_df.to_csv(csv_buffer, index=False)
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
