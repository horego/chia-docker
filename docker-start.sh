#!/usr/bin/env bash

touch "$CHIA_ROOT/log/debug.log"
tail -n0 -F "$CHIA_ROOT/log/debug.log" &

# shellcheck disable=SC2154
if [[ ${farmer} == 'true' ]]; then
  chia start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} || -z ${ca} ]]; then
    echo "A farmer peer address, port, and ca path are required."
    exit
  else
    chia configure --set-farmer-peer "${farmer_address}:${farmer_port}"
    chia start harvester
  fi
elif [[ ${node_farmer_and_wallet} == 'true' ]]; then
  echo "starting farmer"
  chia start farmer
  echo "stopping harvester"
  chia stop harvester
else
  chia start farmer
fi

trap "chia stop all; chia stop all -d; exit 0" SIGINT SIGKILL SIGTERM SIGQUIT

# Ensures the log file actually exists, so we can tail successfully
while true; do sleep 30; done
