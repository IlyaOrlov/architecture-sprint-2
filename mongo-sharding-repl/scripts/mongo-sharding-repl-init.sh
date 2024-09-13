#!/bin/bash

###
# Инициализируем шардированную бд
###

# 1. Инициализируем серверы конфигурации 

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


# 2. Инициализируем replicaset shard1 

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


# 3. Инициализируем replicaset shard2 

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


# 4. Инициализируем роутер

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
