#!/bin/bash

docker build --pull -t dynamodb-mutex -f build/Dockerfile .
