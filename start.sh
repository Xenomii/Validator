#!/bin/bash

./bin/burrow start -c burrow000.toml &
./bin/burrow start -c burrow001.toml &
docker container start itp_network
docker container start itp_memory
docker container start itp_media

