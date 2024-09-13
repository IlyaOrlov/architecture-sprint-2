#!/bin/bash

###
# Инициализируем шардированную бд
###

# 1. Инициализируем серверы конфигурации mongo

docker compose exec -T configSrv1 mongosh --port 27019 --quiet <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv1:27019" },
      { _id : 1, host : "configSrv2:27019" },
      { _id : 2, host : "configSrv3:27019" },
    ]
  }
);
EOF


# 2. Инициализируем mongo replicaSet shard1 

docker compose exec -T shard1-1 mongosh --port 27021 --quiet <<EOF
rs.initiate(
  {
    _id : "shard1",
    members: [
      { _id : 0, host : "shard1-1:27021" },
      { _id : 1, host : "shard1-2:27023" },
      { _id : 2, host : "shard1-3:27025" },
    ]
  }
);
EOF


# 3. Инициализируем mongo replicaSet shard2 

docker compose exec -T shard2-1 mongosh --port 27022 --quiet <<EOF
rs.initiate(
  {
    _id : "shard2",
    members: [
      { _id : 0, host : "shard2-1:27022" },
      { _id : 1, host : "shard2-2:27024" },
      { _id : 2, host : "shard2-3:27026" },
    ]
  }
);
EOF


# 4. Инициализируем роутер mongos

docker compose exec -T mongos_router1 mongosh --port 27017 --quiet <<EOF
sh.addShard("shard1/shard1-1:27021");
sh.addShard("shard1/shard1-2:27023");
sh.addShard("shard1/shard1-3:27025");
sh.addShard("shard2/shard2-1:27022");
sh.addShard("shard2/shard2-2:27024");
sh.addShard("shard2/shard2-3:27026");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
EOF


# 5. Инициализируем Redis Cluster

docker compose exec redis1-1 redis-cli \
  --cluster create   173.17.0.11:6379   173.17.0.12:6379   173.17.0.13:6379   173.17.0.14:6379   173.17.0.15:6379   173.17.0.16:6379 \
  --cluster-replicas 1  --cluster-yes


# 6. Заполняем шардированную бд тестовыми данными

docker compose exec -T mongos_router1 mongosh --port 27017 --quiet <<EOF
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF
