---
name: webhook-tester
description:
  A specialized skill for testing webhook latency, concurrency stability, and returning gameplay architectural recommendations based on test performance.
---

# Webhook Tester

This skill measures the performance of n8n webhooks, especially under heavy bursts (concurrent hits).

When testing gameplay logic (e.g., 5 players requesting images at once), you must use this skill's scripts to quantify how fast the webhook responds and whether it drops any data.

## Scripts:

- `scripts/measure_latency.py`: Measures single webhook latency.
- `scripts/concurrent_test.py`: Measures latency across concurrent tests for numbers ranging from 1 to 5.
