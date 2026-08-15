import os
import gzip
import json
import boto3
from datetime import datetime

s3_client = boto3.client('s3')

def get_latest_log_bucket():
    s3 = boto3.resource('s3')
    for bucket in s3.buckets.all():
        if "sec-telemetry-lab-logs" in bucket.name:
            return bucket.name
    return None

def parse_cloudtrail_logs(bucket_name):
    print(f"[*] Scanning S3 Bucket: {bucket_name} for telemetry logs...\n")
    response = s3_client.list_objects_v2(Bucket=bucket_name, Prefix="AWSLogs/")
    if 'Contents' not in response:
        print("[!] No log files found yet. CloudTrail delivers logs every 5-15 minutes.")
        return
        
    high_risk_events = []
    for obj in response['Contents']:
        key = obj['Key']
        if key.endswith('.json.gz'):
            local_filename = "temp_log.json.gz"
            s3_client.download_file(bucket_name, key, local_filename)
            
            with gzip.open(local_filename, 'rt', encoding='utf-8') as f:
                log_data = json.load(f)
                for record in log_data.get('Records', []):
                    event_name = record.get('eventName')
                    event_time = record.get('eventTime')
                    user_identity = record.get('userIdentity', {}).get('arn', 'Unknown')
                    source_ip = record.get('sourceIPAddress', 'Unknown')
                    
                    if event_name in ['ConsoleLogin', 'AuthorizeSecurityGroupIngress', 'StopLogging', 'DeleteTrail']:
                        high_risk_events.append({
                            'Time': event_time,
                            'Event': event_name,
                            'User': user_identity,
                            'IP': source_ip
                        })
            if os.path.exists(local_filename):
                os.remove(local_filename)
                
    print("====================================================")
    print("        SECURITY OPERATIONS AUDIT SUMMARY REPORT    ")
    print("====================================================")
    if not high_risk_events:
        print("[+] Zero high-risk security events detected in processed logs.")
    else:
        for alert in high_risk_events:
            print(f"[{alert['Time']}] EVENT: {alert['Event']}")
            print(f"  Actor: {alert['User']}")
            print(f"  Source IP: {alert['IP']}")
            print("-" * 52)

if __name__ == "__main__":
    bucket = get_latest_log_bucket()
    if bucket:
        parse_cloudtrail_logs(bucket)
    else:
        print("[!] Target telemetry bucket not found. Ensure Terraform apply was successful.")
