#!/bin/bash
# AfterAllowTraffic Hook - Runs after traffic is shifted to new Lambda version

set -e

echo "Running post-traffic validation..."

FUNCTION_NAME="payment-processing-lambda"
ALIAS="prod"

echo "Validating production traffic on alias: $ALIAS"

# Test the production alias
aws lambda invoke \
  --function-name $FUNCTION_NAME:$ALIAS \
  --payload '{"name": "ProductionHealthCheck"}' \
  --log-type Tail \
  /tmp/prod_response.json

# Verify the response
if grep -q "Hello ProductionHealthCheck" /tmp/prod_response.json; then
  echo "✓ Production validation passed"
  echo "Deployment successful!"
  exit 0
else
  echo "✗ Production validation failed"
  cat /tmp/prod_response.json
  exit 1
fi
