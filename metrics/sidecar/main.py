import os
import sys
import mmap
import json
import argparse
import datetime
import pprint
import random
import time

import googleapiclient.discovery

# Global variables
LOG_WINDOW = 15
LOG_READ_POS = -999
CUSTOM_METRIC_DOMAIN = "custom.googleapis.com"

if "LOG_FILE" not in os.environ:
    print("LOG_FILE environment variable is not defined. This must be defined!!!")
    sys.exit(999)

log_file = os.environ['LOG_FILE']

if "PROJECT_ID" not in os.environ:
    print("PROJECT_ID environment variable is not defined. This must be defined!!!")
    sys.exit(999)

project_id = os.environ['PROJECT_ID']

if "METRIC_NAME" not in os.environ:
    print("METRIC_NAME environment variable is not defined. This must be defined!!!")
    sys.exit(999)

metric_name = os.environ['METRIC_NAME']


def read_log_entries(read_pos):
    with open(log_file, "r+b") as f:
        map_file = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        entry_count = 0
        log_entries = []
        for line in iter(map_file.readline, b""):
            entry_count += 1
            if entry_count >= read_pos:
                log_entries.append(line)

        return log_entries


def format_rfc3339(datetime_instance=None):
    """Formats a datetime per RFC 3339.
    :param datetime_instance: Datetime instanec to format, defaults to utcnow
    """
    return datetime_instance.isoformat("T") + "Z"


def get_start_time():
    # Return now- 5 minutes
    start_time = datetime.datetime.utcnow() - datetime.timedelta(minutes=5)
    return format_rfc3339(start_time)


def get_now_rfc3339():
    # Return now
    return format_rfc3339(datetime.datetime.utcnow())


def write_inference_time_statistics(client, project_resource, custom_metric_path, avg_inf_time):
    """Write the custom metric obtained by get_custom_data_point at a point in
    time."""
    # Specify a new data point for the time series.
    now = get_now_rfc3339()
    timeseries_data = {
        "metric": {
            "type": custom_metric_path,
            "labels": {
                "appName": "mock-yolo"
            }
        },
        "points": [
            {
                "interval": {
                    "startTime": now,
                    "endTime": now
                },
                "value": {
                    "int64Value": avg_inf_time
                }
            }
        ]
    }

    request = client.projects().timeSeries().create(
        name=project_resource, body={"timeSeries": [timeseries_data]})
    request.execute()


# find the start position for the log file
if LOG_READ_POS < 0:
    LOG_READ_POS = 0

# execute a continuous while loop that reads log entries, calculates an aggregate and then writes to cloud monitoring
while 1==1:
    print(f"Reading logs entries from {log_file}.")

    logs = read_log_entries(LOG_READ_POS)

    json_logs = [x.decode('utf-8') for x in logs]

    inf_times = 0
    for json_log in json_logs:
        log_entry = json.loads(json_log)
        print(log_entry)
        inf_times += log_entry['inf_time']

    avg_inf_time = round(inf_times/len(json_logs))
    print(f"Average inf time: {avg_inf_time}")

    # write the metric to cloud monitoring
    project_resource = f"projects/{project_id}"
    # This is our specific metric path
    custom_metric_path = f"{CUSTOM_METRIC_DOMAIN}/{metric_name}"
    client = googleapiclient.discovery.build('monitoring', 'v3')

    write_inference_time_statistics(
        client, 
        project_resource,
        custom_metric_path, 
        avg_inf_time
    )

    # set the new log start cursor
    LOG_READ_POS = sum(1 for line in open(log_file))

    print(f"Sleeping for {LOG_WINDOW} seconds.")
    time.sleep(LOG_WINDOW)
