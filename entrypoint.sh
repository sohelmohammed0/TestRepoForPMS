#!/bin/sh
set -e

TEAM_NAME="${TEAM_NAME:-BillBox}"
APP_ENV="${APP_ENV:-dev}"
SSM_PATH="/${TEAM_NAME}/${APP_ENV}/"

echo "[entrypoint] Fetching parameters from: $SSM_PATH"

NEXT_TOKEN=""
while : ; do
  if [ -z "$NEXT_TOKEN" ]; then
    RESPONSE=$(aws ssm get-parameters-by-path \
      --path "$SSM_PATH" \
      --with-decryption \
      --recursive \
      --output json \
      --region us-east-1 \
      --no-cli-pager)
  else
    RESPONSE=$(aws ssm get-parameters-by-path \
      --path "$SSM_PATH" \
      --with-decryption \
      --recursive \
      --starting-token "$NEXT_TOKEN" \
      --output json \
      --region us-east-1 \
      --no-cli-pager)
  fi

  echo "$RESPONSE" | jq -c '.Parameters[]' 2>/dev/null | while read -r param; do
    KEY=$(echo "$param" | jq -r '.Name' | xargs basename)
    VALUE=$(echo "$param" | jq -r '.Value')
    echo "export ${KEY}=\"${VALUE}\"" >> /tmp/ssm_env.sh
    echo "[entrypoint] Loaded: $KEY"
  done

  NEXT_TOKEN=$(echo "$RESPONSE" | jq -r '.NextToken // empty' 2>/dev/null)
  [ -z "$NEXT_TOKEN" ] && break
done

if [ -f /tmp/ssm_env.sh ]; then
  . /tmp/ssm_env.sh
  rm -f /tmp/ssm_env.sh
fi

echo "[entrypoint] All parameters loaded. Starting app..."
exec "$@"