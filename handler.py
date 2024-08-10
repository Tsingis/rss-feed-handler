import os
import boto3
import feedparser
import json
import logging
from typing import List
from urllib.parse import urlparse

RSS_FEED_URLS = os.environ["RSS_FEED_URLS"]
BUCKET_NAME = os.environ["BUCKET_NAME"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

NOTIFICATION_SUBJECT = "New RSS Feed Entries"

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
        feeds = [url for url in RSS_FEED_URLS.split(";")]
        for feed in feeds:
            logger.info(f"Processing feed {feed}")
            feed_file_key = create_feed_file_key(feed)
            feed = feedparser.parse(feed)
            current_entries: List[dict] = feed.entries
            old_entries = get_old_entries(feed_file_key)
            old_entry_ids = [entry["id"] for entry in old_entries]
            new_entries = [
                create_text(entry)
                for entry in current_entries
                if entry["id"] not in old_entry_ids
            ]
            message = "\n".join(new_entries)
            if not message:
                logger.info("No notification")
            else:
                send_notification(message)
            update_old_entries(current_entries, feed_file_key)
    except Exception:
        logger.exception(f"Error processing feed {feed}")


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


def create_feed_file_key(url: str) -> str:
    domain = urlparse(url).netloc
    return f"""{domain.replace(".", "")}.json"""


def get_old_entries(key: str) -> List[dict]:
    try:
        logger.info(f"Getting object {key}")
        response = s3.get_object(Bucket=BUCKET_NAME, Key=key)
        data = json.loads(response["Body"].read().decode("utf-8"))
        return data.get("entries", [])
    except s3.exceptions.NoSuchKey:
        logger.exception(f"Key {key} not found")
        return list()
    except Exception:
        logger.exception(f"Error getting object {key}")
        return list()


def update_old_entries(entries: List[dict], key: str):
    try:
        logger.info(f"Updating object {key}")
        data = json.dumps({"entries": entries})
        s3.put_object(Bucket=BUCKET_NAME, Key=key, Body=data)
    except Exception:
        logger.exception(f"Error updating object {key}")
