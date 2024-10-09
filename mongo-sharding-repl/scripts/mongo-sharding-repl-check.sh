#!/bin/bash

###
# Проверяем количество документов в шардированной бд и количество реплик
###

check_num_of_docs() {
    server=$1
    port=$2
    
    docker compose exec -T $server mongosh --port $port --quiet <<EOF
use somedb
print("$server:", db.helloDoc.countDocuments())
EOF
}

echo "### Общее количество документов:###"
check_num_of_docs mongos_router1 27017
echo -e "\n###################################\n"

echo "### Количество документов в replicaset shard1: ###"
check_num_of_docs shard1-1 27021
check_num_of_docs shard1-2 27023
check_num_of_docs shard1-3 27025
echo -e "\n##################################################\n"

echo "### Количество документов в replicaset shard2: ###"
check_num_of_docs shard2-1 27022
check_num_of_docs shard2-2 27024
check_num_of_docs shard2-3 27026
echo -e "\n##################################################\n"

echo "### Информация о репликах в shard1: ###"
docker compose exec shard1-1 mongosh --port 27021 --eval "rs.status()" | grep "name\|stateStr"
echo -e "#######################################\n"

echo "### Информация о репликах в shard2: ###"
docker compose exec shard2-1 mongosh --port 27022 --eval "rs.status()" | grep "name\|stateStr"
echo -e "#######################################\n"
