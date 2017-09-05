#!/bin/bash

docker run --name ml9 -d -p 8000:8000 -p 8001:8001 -p 8002:8002 -p 8050:8050 marklogic9

#docker run --name ml9 -d -p 8000:8000 -p 8001:8001 -p 8002:8002 --privileged=true -v /var/opt/MarkLogic:/var/opt/MarkLogic marklogic9
#docker run --name ml9 -d -p 8000:8000 -p 8001:8001 -p 8002:8002 marklogic9
