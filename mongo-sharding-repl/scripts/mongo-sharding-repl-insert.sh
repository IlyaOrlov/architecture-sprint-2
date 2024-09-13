#!/bin/bash

###
# Заполняем шардированную бд тестовыми данными
###

docker compose exec -T mongos_router1 mongosh --port 27017 --quiet <<EOF
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF

