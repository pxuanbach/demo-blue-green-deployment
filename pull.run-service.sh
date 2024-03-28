#!/bin/bash

# Step 1
BLUE_SERVICE="api_blue"
BLUE_SERVICE_PORT=8000
GREEN_SERVICE="api_green"
GREEN_SERVICE_PORT=8001

TIMEOUT=60  # Timeout in seconds
SLEEP_INTERVAL=5  # Time to sleep between retries in seconds
MAX_RETRIES=$((TIMEOUT / SLEEP_INTERVAL))

# Step 2
if docker ps --format "{{.Names}}" | grep -q "$BLUE_SERVICE"; then
  ACTIVE_SERVICE=$BLUE_SERVICE
  INACTIVE_SERVICE=$GREEN_SERVICE
elif docker ps --format "{{.Names}}" | grep -q "$GREEN_SERVICE"; then
  ACTIVE_SERVICE=$GREEN_SERVICE
  INACTIVE_SERVICE=$BLUE_SERVICE
else
  ACTIVE_SERVICE=""
  INACTIVE_SERVICE=$BLUE_SERVICE
fi

echo "Starting $INACTIVE_SERVICE container"

docker compose pull $INACTIVE_SERVICE

docker compose up -d $INACTIVE_SERVICE

# Step 3
# Wait for the new environment to become healthy
echo "Waiting for $INACTIVE_SERVICE to become healthy..."
sleep 10

i=0
while [ "$i" -le $MAX_RETRIES ]; do
  HEALTH_CHECK_URL="http://localhost:8000/health"
  if [ "$INACTIVE_SERVICE" = "$BLUE_SERVICE" ]; then
    HEALTH_CHECK_URL="http://localhost:$BLUE_SERVICE_PORT/health"
  else
    HEALTH_CHECK_URL="http://localhost:$GREEN_SERVICE_PORT/health"
  fi

  response=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_CHECK_URL)
  # Check the HTTP status code
  if [ $response -eq 200 ]; then
      echo "$INACTIVE_SERVICE is healthy"
      break
  else
      echo "Health check failed. API returned HTTP status code: $response"
  fi
  i=$(( i + 1 ))
  sleep "$SLEEP_INTERVAL"
done

# Step 4
# update Nginx config
echo "Update Nginx config to $INACTIVE_SERVICE"
cp ./$INACTIVE_SERVICE.conf /your/config/path/api.conf
# restart nginx
nginx -s reload;

sleep 5

# Step 5
# remove OLD CONTAINER
echo "Remove OLD CONTAINER: $ACTIVE_SERVICE"
docker compose rm -fsv $ACTIVE_SERVICE

# docker compose stop $ACTIVE_SERVICE
# docker compose rm -f $ACTIVE_SERVICE

# remove unused images
(docker images -q --filter 'dangling=true' -q | xargs docker rmi) || true
