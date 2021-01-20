import os
import sys
import argparse
import datetime
import pprint
import random
import time

import googleapiclient.discovery


def create_custom_metric(client, project_resource,
                         custom_metric_type, metric_kind,
                         metric_display_name, metric_description):
    """Create custom metric descriptor"""
    metrics_descriptor = {
        "type": custom_metric_type,
        "labels": [
            {
                "key": "labelKey",
                "valueType": "STRING",
                "description": "An arbitrary measurement"
            }
        ],
        "metricKind": metric_kind,
        "valueType": "INT64",
        "unit": "items",
        "description": metric_description,
        "displayName": metric_display_name
    }

    return client.projects().metricDescriptors().create(
        name=project_resource, body=metrics_descriptor).execute()


def delete_metric_descriptor(client, custom_metric_name):
    """Delete a custom metric descriptor."""
    client.projects().metricDescriptors().delete(
        name=custom_metric_name).execute()


if __name__ == "__main__":
    print(f"Arguments count: {len(sys.argv)}")
    for i, arg in enumerate(sys.argv):
        print(f"Argument {i}: {arg}")
    
    operation = sys.argv[1]
    if operation != "CREATE" and operation != "DELETE":
        print("Invalid operator. Must be CREATE or DELETE.")
        print(f"Usage: python custom_metric.py CREATE project_id metric_descriptor metric_description")
        print(f"Usage: python custom_metric.py DELETE project_id metric_descriptor")
        print(f"Create example: python custom_metric.py CREATE gcp_project_123 my_metric 'This is a metric that does something'")
        print(f"Delete example: python custom_metric.py DELETE gcp_project_123 my_metric")
        sys.exit(999)

    project_id = sys.argv[2]
    metric_descriptor = sys.argv[3]

    # This is the namespace for all custom metrics
    CUSTOM_METRIC_DOMAIN = "custom.googleapis.com"
    # This is our specific metric path
    custom_metric_path = f"{CUSTOM_METRIC_DOMAIN}/{metric_descriptor}"

    if operation == "CREATE":
        metric_description = sys.argv[4]
        
        METRIC_KIND = "GAUGE"
        
        project_resource = f"projects/{project_id}"
        client = googleapiclient.discovery.build('monitoring', 'v3')
        create_custom_metric(
            client, 
            project_resource,
            custom_metric_path,
            METRIC_KIND,
            metric_descriptor,
            metric_description
        )

    if operation == "DELETE":
        project_resource = f"projects/{project_id}"
        client = googleapiclient.discovery.build('monitoring', 'v3')
        delete_metric_descriptor(client, f"{project_resource}/metricDescriptors/{custom_metric_path}")
