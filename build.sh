#!/bin/bash

docker build --build-arg ML_VERSION=9 --build-arg ML_RPM_FILE=MarkLogic-9.0-1.1.x86_64.rpm --build-arg ML_ADMIN_USER=admin --build-arg ML_ADMIN_PASSWORD=admin --rm=true -t marklogic9 .
