#!/bin/bash

read -p "Enter your Spotify CLIENT_ID: " CLIENT_ID

read -p "Enter your Spotify CLIENT_SECRET: " CLIENT_SECRET

if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
  echo "Both CLIENT_ID and CLIENT_SECRET are required."
  exit 1
fi

echo "export SPOTIFY_CLIENT_ID='$CLIENT_ID'" >> ~/.bashrc
echo "export SPOTIFY_CLIENT_SECRET='$CLIENT_SECRET'" >> ~/.bashrc

chmod a+x spotifycli

sudo mv spotifycli /usr/local/bin

echo "Installed SpotifyCLI!"
