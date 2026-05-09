#!/bin/bash
# BeforeAllowTraffic Hook - Runs before traffic is shifted to new Lambda version

set -e

echo "Running pre-traffic validation tests..."

# Extract deployment details from environment variables
NEW_VERSION=$DeploymentId
FUNCTION_NAME="payment-processing-lambda"

echo "Testing new Lambda version: $NEW_VERSION"

# Test the new version with a sample payload
aws lambda invoke \
  --function-name $FUNCTION_NAME:$NEW_VERSION \
  --payload '{"name": "HealthCheck"}' \
  --log-type Tail \
  /tmp/response.json

# Check the response
if grep -q "Hello HealthCheck" /tmp/response.json; then
  echo "✓ Lambda validation passed"
  exit 0
else
  echo "✗ Lambda validation failed"
  cat /tmp/response.json
  exit 1
fi
