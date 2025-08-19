import os
import boto3
import feedparser
import json
import logging
from typing import List
from urllib.parse import urlparse


local = os.getenv("AWS_LAMBDA_FUNCTION_NAME") is None

if local:
    from dotenv import load_dotenv

    load_dotenv()


RSS_FEEDS_URLS = os.getenv("RSS_FEEDS_URLS")
BUCKET = os.getenv("RSS_FEEDS_BUCKET")
TOPIC_ARN = os.getenv("RSS_FEEDS_TOPIC_ARN")
ACCOUNT_ID = os.getenv("AWS_ACCOUNT_ID")

NOTIFICATION_SUBJECT = "New RSS Feed Entries"

s3 = boto3.client("s3")
sns = boto3.client("sns")

logger = logging.getLogger(__name__)
logFormat = "%(asctime)s %(levelname)s: %(message)s"
logging.basicConfig(level=logging.INFO, format=logFormat, force=True)


def handler(event: dict, context: dict):
    process_feeds()


def process_feeds():
    feed_urls = RSS_FEEDS_URLS.split(";")
    for feed_url in feed_urls:
        process_feed(feed_url)


def process_feed(feed_url: str):
    try:
        logger.info(f"Processing feed {feed_url}")
        feed_file_key = create_feed_file_key(feed_url)
        feed = feedparser.parse(feed_url)
        current_entries: List[dict] = feed.entries
        old_entries = get_old_entries(feed_file_key)
        update_old_entries(current_entries, feed_file_key)
        if not old_entries:
            logger.info(f"Feed {feed_url} entries initialized")
            return
        old_entry_ids = [entry["id"] for entry in old_entries]
        new_entries = [
            create_text(entry)
            for entry in current_entries
            if entry["id"] not in old_entry_ids
        ]
        if new_entries:
            message = "\n".join(new_entries)
            if local:
                logger.debug(message)
            else:
                send_notification(message)
        else:
            logger.info(f"No new entries in feed {feed_url}")
    except Exception:
        logger.exception(f"Error processing feed {feed_url}")


def send_notification(message: str):
    try:
        logger.info("Publishing notification")
        sns.publish(
            TopicArn=TOPIC_ARN,
            Subject=NOTIFICATION_SUBJECT,
            Message=message,
        )
    except Exception:
        logger.exception("Error publishing notification")


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
        response = s3.get_object(Bucket=BUCKET, Key=key, ExpectedBucketOwner=ACCOUNT_ID)
        data = json.loads(response["Body"].read().decode("utf-8"))
        return data.get("entries", [])
    except s3.exceptions.NoSuchKey:
        logger.warning(f"Object {key} not found")
        return []
    except Exception:
        logger.exception(f"Error getting object {key}")


def update_old_entries(entries: List[dict], key: str):
    try:
        logger.info(f"Updating object {key}")
        data = json.dumps({"entries": entries})
        s3.put_object(Bucket=BUCKET, Key=key, Body=data, ExpectedBucketOwner=ACCOUNT_ID)
    except Exception:
        logger.exception(f"Error updating object {key}")


if __name__ == "__main__":
    process_feeds()
