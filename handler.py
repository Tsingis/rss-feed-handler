import os
import boto3
import feedparser
import json
import logging
from typing import List

RSS_FEED_URL = os.environ["RSS_FEED_URL"]
BUCKET_NAME = os.environ["BUCKET_NAME"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

NOTIFICATION_SUBJECT = "New RSS Feed Entries"
OBJECT_KEY = "entries.json"

s3 = boto3.client("s3")
sns = boto3.client("sns")

logger = logging.getLogger()
if logger.handlers:
    for handler in logger.handlers:
        logger.removeHandler(handler)

logFormat = "%(asctime)s %(name)s %(levelname)s: %(message)s"
logging.basicConfig(level=logging.INFO, format=logFormat)


def handler(event: dict, context: dict):
    process_feed()


def process_feed() -> str:
    try:
        logger.info("Processing feed")
        feed = feedparser.parse(RSS_FEED_URL)
        current_entries: List[dict] = feed.entries
        old_entries = get_old_entries()
        old_entry_ids = [entry["id"] for entry in old_entries]
        new_entries = [
            create_text(entry)
            for entry in current_entries
            if entry["id"] not in old_entry_ids
        ]
        message = "\n".join(new_entries)
        if not message or message is None:
            logger.info("No notification")
        else:
            send_notification(message)
        update_old_entries(current_entries)
    except Exception:
        logger.exception("Error processing feed")


def send_notification(message: str):
    try:
        logger.info("Publishing notification")
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=NOTIFICATION_SUBJECT,
            Message=message,
        )
    except Exception:
        logger.exception("Error publishing to topic")


def create_text(entry: dict) -> str:
    title = entry.get("title", None)
    link = entry.get("link", None)
    return f"Title: {title}\nLink: {link}\n"


def get_old_entries() -> List[dict]:
    try:
        logger.info(f"Getting object {OBJECT_KEY}")
        response = s3.get_object(Bucket=BUCKET_NAME, Key=OBJECT_KEY)
        data = json.loads(response["Body"].read().decode("utf-8"))
        return data.get("entries", [])
    except s3.exceptions.NoSuchKey:
        logger.exception(f"Key {OBJECT_KEY} not found")
        return list()
    except Exception:
        logger.exception(f"Error getting object {OBJECT_KEY}")
        return list()


def update_old_entries(entries: List[dict]):
    try:
        logger.info(f"Updating object {OBJECT_KEY}")
        data = json.dumps({"entries": entries})
        s3.put_object(Bucket=BUCKET_NAME, Key=OBJECT_KEY, Body=data)
    except Exception:
        logger.exception(f"Error updating object {OBJECT_KEY}")
