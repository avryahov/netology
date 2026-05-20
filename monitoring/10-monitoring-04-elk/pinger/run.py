#!/usr/bin/env python3

import json
import logging
import random
import sys
import time
from datetime import datetime, timezone


class JsonHandler(logging.Handler):
    def emit(self, record):
        timestamp = datetime.fromtimestamp(record.created, tz=timezone.utc).strftime('%Y-%m-%dT%H:%M:%S')

        log_entry = {
            "@timestamp": timestamp + "Z",
            "log.level": record.levelname,
            "message": record.getMessage(),
            "logger.name": record.name,
        }

        if record.exc_info:
            log_entry["error.message"] = str(record.exc_info[1])

        print(json.dumps(log_entry))
        sys.stdout.flush()


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

handler = JsonHandler()
logger.addHandler(handler)

while True:
    number = random.randrange(0, 4)

    if number == 0:
        logger.info('Hello there!!')
    elif number == 1:
        logger.warning('Hmmm....something strange')
    elif number == 2:
        logger.error('OH NO!!!!!!')
    elif number == 3:
        try:
            raise Exception('this is exception')
        except Exception as e:
            logger.exception(e)

    time.sleep(1)
