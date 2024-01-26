import time
import os
import boto3
import json
import urllib.request


ddb_table = boto3.resource('dynamodb').Table(os.environ["DDB_TABLE"])
logs = boto3.client('logs')
new_last_id = 0

def cwlog(message):
    LOG_GROUP = os.environ['LOG_GROUP']
    LOG_STREAM = 'ApplicationLogs'
    global logs
    timestamp = int(round(time.time() * 1000))

    logs.put_log_events(
        logGroupName=LOG_GROUP,
        logStreamName=LOG_STREAM,
        logEvents=[
            {
                'timestamp': timestamp,
                'message': time.strftime('%Y-%m-%d %H:%M:%S')+'\t'+message
            }
        ]
    )


def post_slack(slack_webhook, pendo_list):
    payload = build_slack_message(pendo_list)
    json_payload = json.dumps(payload)
    x = urllib.request.urlopen(urllib.request.Request(slack_webhook, data=json_payload.encode('utf-8'), headers={'Content-Type': 'application/json'}, method='POST'))

def get_pendo_data(last_id):
    global new_last_id
    pendo_key = os.environ["PENDO_KEY"]
    url = "https://api.feedback.us.pendo.io/features?limit=50&auth-token=" + pendo_key
    req = urllib.request.urlopen(urllib.request.Request(url, headers={'Accept': 'application/json'}, method='GET'))
    data = json.loads(req.read())
    pendo_list = []
    new_last_id = 0

    for item in data:
        if int(item["id"]) == last_id:
            break
        if new_last_id == 0:
            new_last_id = int(item["id"])
        pendo_list.append(
            {
                "type": "rich_text_section",
                "elements": [
                    {
                        "type": "link",
                        "text": item["title"],
                        "url": "https://feedback.us.pendo.io/app/#/case/" + str(item["id"])
                    }
                ]
            }
        )
    
    return pendo_list

def build_slack_message(pendo_list):
    lmessage = "Hi Team!\n\nPlease review these most recent feature request. Remember to tag any of your accounts that may share the same need/request, link SFDC opps to them where possible! If you have any questions or comments, feel free to add them directly to a feature request."
    
    if new_last_id != 0:
        payload = {
            "text": lmessage,
            "blocks": [
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "Hi Team!\n\nPlease review these most recent feature request. Remember to tag any of your accounts that may share the same need/request, link SFDC opps to them where possible! If you have any questions or comments, feel free to add them directly to a feature request."
                    }
                },
                {
                    "type": "rich_text",
                    "elements": [
                        {
                            "type": "rich_text_list",
                            "elements": pendo_list,
                            "style": "bullet",
                            "indent": 0
                        }
                    ]
                },
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "Thanks!\nCoE Team"
                    }
                }
            ]
        }
    else:
        payload = {
            "text": lmessage,
            "blocks": [
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "Hi Team!\n\nIt looks like there are no new feature requests since our last notification. Be sure to add new requests from your customers and prospects. If you have any new ideas, feel free to enter those as well!"
                    }
                },
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "<https://feedback.us.pendo.io/app/#/vendor/suggest|Enter a new feature request is Pendo>"
                    }
                },
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "Thanks!\nCoE Team"
                    }
                }
            ]
        }
    return payload

def update_last_id():
    global new_last_id
    global ddb_table

    if new_last_id != 0:
        ddb_table.update_item(
            Key={'AppId': os.environ["PENDO_ID"]},
            UpdateExpression="set NumberItem = :g",
            ExpressionAttributeValues={
                ':g': new_last_id
            },
            ReturnValues="UPDATED_NEW"
        )
        cwlog("NumberItem updated in DDB Table")

    return new_last_id


def lambda_handler(event, context):
    global ddb_table
    
    slack_webhook = os.environ["SLACK_WEBHOOK"]
    cwlog("Get data from DDB table")
    item = ddb_table.get_item(Key={'AppId': os.environ["PENDO_ID"]})
    if "Item" in item:
        rec = item["Item"]
        last_id = int(rec["NumberItem"])
        retval = '{"last_id": ' + str(int(rec["NumberItem"])) + '}'
        cwlog("Data retrieved: " + str(retval))
        cwlog("Getting newest Pendo requests")
        pendo_list = get_pendo_data(last_id)
        cwlog(str(len(pendo_list)) + " new item(s)")
        cwlog("Posting to Slack...")
        post_slack(slack_webhook, pendo_list)
        update_last_id()
        cwlog("Last ID: " + str(new_last_id))
        cwlog("Complete!")
    else:
        cwlog("An error occurred trying to retrieve AppId:" + os.environ["PENDO_ID"] + ". The record does not exist!")


    return {
        'isBase64Encoded': False,
        'statusCode': 200,
        'body': "Success!"
    }
