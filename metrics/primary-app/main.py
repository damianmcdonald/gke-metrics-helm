import os
import sys
import time
import random
import logging
import json_logging

# Global variables
LOG_WINDOW = 2


def get_logger():
    """
    Generic utility function to get logger object with fixed configurations
    :return:
    log object
    """

    if "LOG_FILE" not in os.environ:
        print("LOG_FILE environment variable is not defined. This must be defined!!!")
        sys.exit(999)

    log_file = os.environ['LOG_FILE']

    json_logging.init_non_web(enable_json=True)

    log = logging.getLogger(__name__)
    log.setLevel(logging.DEBUG)
    log.addHandler(logging.FileHandler(log_file))
    log.addHandler(logging.StreamHandler(sys.stdout))

    return log


def write_log_entry():
    inf_time = random.randint(1, 10) * 1000
    mem_usage = random.randint(1, 10) * 100
    logger.info("Executed inference",
                extra={'props':
                        {
                            'app_name': 'yolo-reco',
                            'inf_time': inf_time,
                            'mem_usage': f"{mem_usage}Mi"
                        }
                    }
                )


# grab the logger object
logger = get_logger()

# execute a continuous while loop that writes log entries
while 1==1:
    print(f"Executing a mock action that generates logs.")
    write_log_entry()
    print(f"Sleeping for {LOG_WINDOW} seconds.")
    time.sleep(LOG_WINDOW)
