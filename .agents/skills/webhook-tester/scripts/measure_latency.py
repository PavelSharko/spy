import requests
import time
import sys
import json

def measure_latency(url, payload=None, auth=None):
    start_time = time.time()
    try:
        response = requests.post(url, json=payload, auth=auth, timeout=30)
        end_time = time.time()
        latency = end_time - start_time
        print(f"Status: {response.status_code}, Time: {latency:.2f}s, Bytes: {len(response.content)}")
        return latency
    except Exception as e:
        print(f"Error: {e}")
        return None

if __name__ == "__main__":
    url = "https://n8n.sharksbots.com/webhook/get-scene-picture"
    measure_latency(url)
