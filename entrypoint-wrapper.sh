#!/usr/bin/env sh

ALEPHIUM_HOME=${ALEPHIUM_HOME:-/alephium-home/.alephium}
ALEPHIUM_NETWORK=${ALEPHIUM_NETWORK:-mainnet}
ALEPHIUM_API_KEY=${ALEPHIUM_API_KEY:-}  # new env var for API key

# Call snapshot-loader.sh and ensure it completed successfully, stopping the execution otherwise.
if ! ./snapshot-loader.sh
then
  echo "Loading the snapshot failed. See logs above for more details, apply recommended actions and retry"
  exit 1
fi

# Copy default user.conf if it does not exists already
if [ ! -f "$ALEPHIUM_HOME/user.conf" ]
then
    echo "Copying standalone user.conf file"
    cp "/user-$ALEPHIUM_NETWORK.conf" "$ALEPHIUM_HOME/user.conf"
fi

# Update user.conf with API key
sed -i "s/alephium.api.api-key-enabled = false/alephium.api.api-key-enabled = true/" "$ALEPHIUM_HOME/user.conf"
sed -i "s/alephium.api.api-key = \"/alephium.api.api-key = \"$ALEPHIUM_API_KEY\"/" "$ALEPHIUM_HOME/user.conf"

# Update Custom Network Bind Address
sed -i "s/alephium.network.bind-address  = \"0.0.0.0:39973\"/alephium.network.bind-address  = \"$ALEPHIUM_NETWORK_BIND_ADDRESS\"/" "$ALEPHIUM_HOME/user.conf"

# Set Internal and/or Coordinator Address

if [ -n "$ALEPHIUM_NETWORK_INTERNAL_ADDRESS" ] && [ -n "$ALEPHIUM_NETWORK_COORDINATOR_ADDRESS" ]; then
  sed -i "/alephium.network.internal-address  = /a alephium.network.internal-address  = \"$ALEPHIUM_NETWORK_INTERNAL_ADDRESS\"" "$ALEPHIUM_HOME/user.conf"
  sed -i "/alephium.network.coordinator-address  = /a alephium.network.coordinator-address  = \"$ALEPHIUM_NETWORK_COORDINATOR_ADDRESS\"" "$ALEPHIUM_HOME/user.conf"
elif [ -n "$ALEPHIUM_NETWORK_INTERNAL_ADDRESS" ]; then
  sed -i "/alephium.network.internal-address  = /a alephium.network.internal-address  = \"$ALEPHIUM_NETWORK_INTERNAL_ADDRESS\"" "$ALEPHIUM_HOME/user.conf"
elif [ -n "$ALEPHIUM_NETWORK_COORDINATOR_ADDRESS" ]; then
  sed -i "/alephium.network.coordinator-address  = /a alephium.network.coordinator-address  = \"$ALEPHIUM_NETWORK_COORDINATOR_ADDRESS\"" "$ALEPHIUM_HOME/user.conf"
fi

echo "Now starting Alephium full node!"

# Call the official entrypoint of the parent image `alephium/alephium`
exec /entrypoint.sh "$@"
