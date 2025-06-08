#!/usr/bin/env python3
import boto3
import json
import sys
import time
import argparse

def start_and_wait_for_ingestion(knowledge_base_id, data_source_id, region='us-west-2', timeout_minutes=30):
    """Start ingestion job and wait for completion"""

    # Initialize clients
    bedrock_agent = boto3.client('bedrock-agent', region_name=region)

    print(f"Starting ingestion for Knowledge Base: {knowledge_base_id}, Data Source: {data_source_id}")

    try:
        # Start ingestion job
        response = bedrock_agent.start_ingestion_job(
            knowledgeBaseId=knowledge_base_id,
            dataSourceId=data_source_id
        )

        job_id = response['ingestionJob']['ingestionJobId']
        print(f"Ingestion job started with ID: {job_id}")

        # Wait for completion
        timeout_seconds = timeout_minutes * 60
        start_time = time.time()

        while True:
            # Check if timeout reached
            if time.time() - start_time > timeout_seconds:
                print(f"Timeout reached ({timeout_minutes} minutes). Ingestion may still be running.")
                return False

            # Check job status
            job_response = bedrock_agent.get_ingestion_job(
                knowledgeBaseId=knowledge_base_id,
                dataSourceId=data_source_id,
                ingestionJobId=job_id
            )

            status = job_response['ingestionJob']['status']
            statistics = job_response['ingestionJob'].get('statistics', {})

            print(f"Ingestion status: {status}")
            if statistics:
                scanned = statistics.get('numberOfDocumentsScanned', 0)
                indexed = statistics.get('numberOfNewDocumentsIndexed', 0)
                failed = statistics.get('numberOfDocumentsFailed', 0)
                print(f"  Documents - Scanned: {scanned}, Indexed: {indexed}, Failed: {failed}")

            if status == 'COMPLETE':
                print("✅ Ingestion completed successfully!")
                print(f"Final statistics: {json.dumps(statistics, indent=2)}")
                return True
            elif status == 'FAILED':
                failure_reasons = job_response['ingestionJob'].get('failureReasons', [])
                print(f"❌ Ingestion failed!")
                if failure_reasons:
                    print(f"Failure reasons: {failure_reasons}")
                return False
            elif status in ['STARTING', 'IN_PROGRESS']:
                # Continue waiting
                time.sleep(10)
            else:
                print(f"Unknown status: {status}")
                time.sleep(10)

    except Exception as e:
        print(f"Error during ingestion: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Start and monitor Bedrock Knowledge Base ingestion')
    parser.add_argument('knowledge_base_id', help='Bedrock Knowledge Base ID')
    parser.add_argument('data_source_id', help='Data Source ID')
    parser.add_argument('--region', default='us-west-2', help='AWS region (default: us-west-2)')
    parser.add_argument('--timeout', type=int, default=30, help='Timeout in minutes (default: 30)')

    args = parser.parse_args()

    success = start_and_wait_for_ingestion(
        args.knowledge_base_id,
        args.data_source_id,
        args.region,
        args.timeout
    )

    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
