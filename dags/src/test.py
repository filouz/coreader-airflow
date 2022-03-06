from feed_service import rssScraper, feedBrainVector
import logging

logging.basicConfig(level=logging.INFO)

rssScraper("coindesk", "https://www.coindesk.com/arc/outboundfeeds/rss/")
