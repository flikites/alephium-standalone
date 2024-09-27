#!/usr/bin/env sh

ALEPHIUM_HOME=${ALEPHIUM_HOME:-/data}
ALEPHIUM_NETWORK=${ALEPHIUM_NETWORK:-mainnet}
ALEPHIUM_API_KEY=${ALEPHIUM_API_KEY:-""}  # Add API key environment variable
ALEPHIUM_NETWORK_BIND_ADDRESS=${ALEPHIUM_NETWORK_BIND_ADDRESS:-39973}  # Default bind address
ALEPHIUM_NETWORK_COORDINATOR_ADDRESS=${ALEPHIUM_NETWORK_COORDINATOR_ADDRESS:-""}  # Coordinator address
ALEPHIUM_NETWORK_INTERNAL_ADDRESS=${ALEPHIUM_NETWORK_INTERNAL_ADDRESS:-""}  # Internal address

# Call snapshot-loader.sh and ensure it completed successfully, stopping the execution otherwise.
if ! ./snapshot-loader.sh
then
  echo "Loading the snapshot failed. See logs above for more details, apply recommended actions and retry"
  exit 1
fi

# Copy default user.conf if it does not exist already
if [ ! -f "$ALEPHIUM_HOME/user.conf" ]
then
    echo "Copying standalone user.conf file"
    cp "/user-$ALEPHIUM_NETWORK.conf" "$ALEPHIUM_HOME/user.conf"
fi

# Update the user.conf file with the API key and conditionally enable it
if [ -n "$ALEPHIUM_API_KEY" ]; then
  echo "Updating user.conf with API key"
  sed -i "/^alephium.api.api-key =/d" "$ALEPHIUM_HOME/user.conf"  # Remove existing api-key line
  echo "alephium.api.api-key = \"$ALEPHIUM_API_KEY\"" >> "$ALEPHIUM_HOME/user.conf"  # Add the new api-key line
  
  # Enable the API key in user.conf
  sed -i 's/^alephium.api.api-key-enabled = false/alephium.api.api-key-enabled = true/' "$ALEPHIUM_HOME/user.conf"
fi

# Update bind address in user.conf
sed -i "s|^alephium.network.bind-address = .*|alephium.network.bind-address = \"$ALEPHIUM_NETWORK_BIND_ADDRESS\"|" "$ALEPHIUM_HOME/user.conf"

# Add the coordinator address if it is set and doesn't already exist
if [ -n "$ALEPHIUM_NETWORK_COORDINATOR_ADDRESS" ]; then
  if ! grep -q "^alephium.network.coordinator-address =" "$ALEPHIUM_HOME/user.conf"; then
    echo "alephium.network.coordinator-address = \"$ALEPHIUM_NETWORK_COORDINATOR_ADDRESS\"" >> "$ALEPHIUM_HOME/user.conf"
  fi
fi

# Add the internal address if it is set and doesn't already exist
if [ -n "$ALEPHIUM_NETWORK_INTERNAL_ADDRESS" ]; then
  if ! grep -q "^alephium.network.internal-address =" "$ALEPHIUM_HOME/user.conf"; then
    echo "alephium.network.internal-address = \"$ALEPHIUM_NETWORK_INTERNAL_ADDRESS\"" >> "$ALEPHIUM_HOME/user.conf"
  fi
fi

echo "Now starting Alephium full node!"

# Call the official entrypoint of the parent image `alephium/alephium`
exec /entrypoint.sh "$@"
