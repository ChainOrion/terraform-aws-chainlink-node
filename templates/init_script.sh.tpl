mkdir ~/chainlink
echo $KEYSTORE_PASSWORD | base64 -d > ~/chainlink/.password
echo $API_CREDENTIALS | base64 -d > ~/chainlink/.api
export AZ='\"'$(curl -s $ECS_CONTAINER_METADATA_URI_V4/task | python3 -c \"import sys, json; print(json.load(sys.stdin)['AvailabilityZone'])\")'\"'
export P2P_ANNOUNCE_IP=$(echo $SUBNET_MAP | base64 -d | python3 -c \"import sys, json; print(json.load(sys.stdin)[$AZ]['ip'])\")
export DATABASE_URL=$(echo $DATABASE_URL | base64 -d)
echo [INFO] AvailabilityZone $AZ
echo [INFO] P2P_ANNOUNCE_IP $P2P_ANNOUNCE_IP
echo [INFO] P2P_ANNOUNCE_PORT $P2P_ANNOUNCE_PORT
[ \"$TLS_UI_ENABLED\" = \"true\" ] && echo \"[INFO] TLS is enabled on Chainlink Node. Importing...\" || echo \"[INFO] TLS is not enabled on Chainlink Node\"
[ \"$TLS_UI_ENABLED\" = \"true\" ] && echo $TLS_CERT | base64 -d > ~/chainlink/server.crt && export TLS_CERT_PATH=~/chainlink/server.crt || true
[ \"$TLS_UI_ENABLED\" = \"true\" ] && echo $TLS_KEY | base64 -d > ~/chainlink/server.key && export TLS_KEY_PATH=~/chainlink/server.key || true
[ \"$TLS_UI_ENABLED\" = \"true\" ] && export SECURE_COOKIES=true || export SECURE_COOKIES=false
[ \"$TLS_UI_ENABLED\" = \"true\" ] || export CHAINLINK_TLS_PORT=0
[ ! -z \"$TLS_CERT_PATH\" ] && [ ! -z \"$TLS_KEY_PATH\" ] && echo \"[INFO] TLS certificate and server key imported\" || echo \"[INFO] Skip TLS certificate and server key import\"
chainlink local node -p ~/chainlink/.password -a ~/chainlink/.api