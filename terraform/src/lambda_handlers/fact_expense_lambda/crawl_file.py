import json
import requests
import re
import boto3
from bs4 import BeautifulSoup
from datetime import datetime
import unicodedata

s3 = boto3.client('s3')

# get the list of already downloaded files
def get_downloaded_list(bucket, key):
    try:
        response = s3.get_object(Bucket=bucket, Key=key)
        content = response['Body'].read().decode('utf-8')
        return content
    except Exception as e:
        print(f"Error retrieving downloaded list file: {e}")

def get_new_filename(downloaded_list):
    try:
        # get the information of latest file downloaded
        last_line = downloaded_list.split("\n")[-1]
        match = re.match(r'(\d{4})年(\d{1,2})月', last_line)
        if not match:
            return None
        year = int(match.group(1))
        month = int(match.group(2))

        # the file name for the file that need to be downloaded next
        new_filename = f'{year+1}年1月' if month == 12 else f'{year}年{month+1}月'
        return new_filename
    except Exception as e:
        print(e)
        return None

def find_target_data_page(url, file_name):
    response = requests.get(url)
    soup = BeautifulSoup(response.content, "html.parser")
    match = re.match(r'(\d{4}年)(\d{1,2}月)', file_name)

    for ul in soup.find_all("ul", class_="stat-cycle_ul_other"):
        year = ul.find("li", class_ = "stat-cycle_header").text.strip()
        if year != match.group(1):
            continue
        li = ul.find("li", class_ = "stat-cycle_item")
        for a in li.find_all("a", class_="stat-item_child"):
            month = a.text.strip()
            if f"{year}{month}" == file_name:
                return a["href"]
    return None


def get_excel_link(base_url, data_pth):
    print("Get excel link...")
    response = requests.get(base_url + data_pth)
    soup = BeautifulSoup(response.content, "html.parser")
    for ul in soup.find_all("ul", class_="stat-dataset_list-detail"):
        if ul.select("li.stat-dataset_list-detail-item span:nth-child(2)")[0].text.strip() == "1-1":
            excel_file_url = base_url + ul.find("a", attrs = {"data-file_type":"EXCEL"})["href"]
            return excel_file_url
    return None

# download the excel file and place in s3 bucket
def download_excel_file(url, file_name, target_bucket, target_folder):
    print("Download file...")
    file_res = requests.get(url)
    # place excel file
    s3.put_object(
        Bucket=target_bucket,
        Key=target_folder + "/"+ file_name,
        Body=file_res.content
    )


def lambda_handler(event, context):
    downloaded_list = get_downloaded_list(event["target_bucket"], event["downloaded_list"])
    new_filename = get_new_filename(downloaded_list)
    if not event["stat_url"] or not event["stat_url"] or not event["base_url"]:
        return {"status": 400, "body": json.dumps("Cannot get the stat url and base url from event")}

    if not new_filename :
        return {"status": 400, "body": json.dumps("Cannot get the new file name")}

    data_pth = find_target_data_page(event["stat_url"], new_filename)
    if not data_pth:
        return {"status": 404, "body": json.dumps(f"Cannot find {new_filename.encode('utf-8').decode('unicode_escape')} data page. Job ended")}
    print(f"Found {new_filename} data page. Find link to download excel file...")
    try:
        excel_link = get_excel_link(event["base_url"],data_pth)
        if excel_link:
            # target data year and month
            year = new_filename.split("年")[0]
            month = new_filename.split("年")[1].split("月")[0].zfill(2)
            file_name = f"expense_{year}{month}_{datetime.now().strftime('%Y%m%d')}.xlsx"
            file_name = unicodedata.normalize("NFC", file_name)
            download_excel_file(excel_link, file_name, event["target_bucket"], event["target_folder"])

            # update and save list of already downloaded file
            downloaded_list+= "\n"+ new_filename
            s3.put_object(
                Bucket=event["target_bucket"],
                Key=event["downloaded_list"],
                Body=downloaded_list
            )
            return {"status": 200, 
                    "output_file": file_name,
                    "body": json.dumps(f"{new_filename} data was successfully downloaded"), 
                    "function_name": context.function_name
                    }
    except Exception as e:
        print("Job failed. " + str(e))
        return {"status": 500, "body": json.dumps(f"Job failed. {str(e)}")}