#!/bin/bash

docker run --rm -t dynamodb-mutex bundle exec rspec
