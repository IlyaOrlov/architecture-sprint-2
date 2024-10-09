#!/bin/bash

###
# Проверяем количество документов в шардированной бд
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

echo "### Количество документов в shard1: ###"
check_num_of_docs shard1 27021
echo -e "\n##################################################\n"

echo "### Количество документов в shard2: ###"
check_num_of_docs shard2 27022
echo -e "\n##################################################\n"
