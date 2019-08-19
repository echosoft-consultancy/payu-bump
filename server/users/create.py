import decimal
import json
import time
import uuid
from decimal import Decimal

import boto3
from haversine import haversine

dynamodb = boto3.resource('dynamodb')


def create(event, context):
    table = dynamodb.Table('accelerometer-users-dev')
    data = json.loads(event['body'])
    table.put_item(
        Item={
            'id': str(uuid.uuid4()),
            'name': data["name"],
            "lat": Decimal(str(data["lat"])),
            "long": Decimal(str(data["long"])),
            "bump_time": data["bump_time"],
            "ttl": Decimal(time.time() + 30)
        }
    )
    print(f"Received data {data}")

    found_users = []
    response = table.scan()
    found_users = found_users + find_user(data, response)

    while 'LastEvaluatedKey' in response:
        response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
        found_users = found_users + find_user(data, response)

    print(f"All found users {found_users}, {type(found_users)}")
    body = [
        {
            "name": item["name"],
            "lat": float(str(item["lat"])),
            "long": float(str(item["long"])),
            "bump_time": float(str(item["bump_time"]))
        } for item in found_users]

    print(f"Body {body}")
    response = {
        "statusCode": 200,
        "body": json.dumps(body)
    }

    return response


def find_user(data, response):
    found_users = []
    print(f"Found items {response['Items']}")
    for item in response['Items']:
        distance_from_eachother = haversine((data["lat"], data["long"]), (item["lat"], item["long"]),
                                            unit='m')
        time_difference = abs(data["bump_time"] - item["bump_time"])
        print(f"Distance={distance_from_eachother}, time_difference={time_difference}")
        if distance_from_eachother < 10 and time_difference < 10000000 and data["name"] != item["name"]:
            print(f"Found user {item}")
            found_users.append(item)
    return found_users
