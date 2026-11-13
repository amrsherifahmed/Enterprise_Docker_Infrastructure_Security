#!/bin/bash
set -e

echo "=============================="
echo " Trivy Security Scan Report"
echo "=============================="
echo ""

IMAGES=(
  "dockercompose-app-app"
  "dockercompose-app-nginx"
  "mariadb:10.11"
  "memcached:1.6-alpine"
  "rabbitmq:3.13-alpine"
)

SEVERITY="HIGH,CRITICAL"
EXIT_CODE=0

for IMAGE in "${IMAGES[@]}"; do
  echo "-------------------------------"
  echo "Scanning: $IMAGE"
  echo "-------------------------------"
  
  trivy image --severity "$SEVERITY" --exit-code 1 "$IMAGE" || EXIT_CODE=1
  
  echo ""
done

echo "=============================="
if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ All images passed security scan"
else
  echo "❌ Vulnerabilities found — review the report above"
fi
echo "=============================="

exit $EXIT_CODE