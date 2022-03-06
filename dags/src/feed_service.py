import hashlib
import feedparser
from pymongo import MongoClient
from bson.json_util import dumps, loads
import redis
import logging
import json

class BaseRssParser:
    def __init__(self, url):
        self.url = url

    def fetch_feed(self):
        return feedparser.parse(self.url)

    def parse_feed(self, feed):
        for entry in feed.entries:
            guid = entry.get('guid', '')
            title = entry.get('title', '')
            link = entry.get('link', '')
            tags = tags = [tag.term for tag in entry.get('tags', [])]

            content = entry.get('summary')
            if not content or len(content) < 10:
                content_data = entry.get('content', [{}])
                if isinstance(content_data, list) and isinstance(content_data[0], dict):
                    content = content_data[0].get('value', '')
                
            if not content or len(content) < 10:
                content = title

            yield guid, title, link, content, tags, entry

def rssScraper(feed_name, feed_link):

    parser = BaseRssParser(feed_link)
    client = MongoClient('mongodb://mongo:27017/')
    db = client['feed_db']
    collection = db[feed_name]

    feed = parser.fetch_feed()

    count = 0
    for guid, title, link, content, tags, record in parser.parse_feed(feed):

        recordHash = hashlib.sha256(guid.encode()).hexdigest()

        if collection.find_one({'_id': recordHash}) is None:
            article = {
                '_id': recordHash,
                'title': title,
                'link': link,
                'content': content,
                'tags': tags,
                'record': record
            }
            collection.insert_one(article)
            logging.info("=> record scrapped: %s", recordHash)
            count += 1

    return json.dumps({
        'mongo_inserts_{}'.format(feed_name): count
    })


def feedBrainVector(name):

    mongo_client = MongoClient('mongodb://mongo:27017/')
    db = mongo_client['feed_db']
    collection = db[name]

    redis_client = redis.Redis(host='redis', port=6379)

    records = list(collection.find())

    count = 0
    for record in records:
        record_json = dumps(record)
        redis_client.rpush(name, record_json)
        logging.info("=> record pushed: %s", record['_id'])
        count += 1

    return json.dumps({
        'redis_pushes_{}'.format(name): count
    })
