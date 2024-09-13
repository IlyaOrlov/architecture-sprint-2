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


# 2. Инициализируем шарды (1) 

docker compose exec -T shard1 mongosh --port 27021 --quiet <<EOF
rs.initiate(
  {
    _id : "shard1",
    members: [
      { _id : 0, host : "shard1:27021" },
      // { _id : 1, host : "shard2:27022" }
    ]
  }
);
EOF


# 3. Инициализируем шарды (2) 

docker compose exec -T shard2 mongosh --port 27022 --quiet <<EOF
rs.initiate(
  {
    _id : "shard2",
    members: [
     // { _id : 0, host : "shard1:27021" },
     { _id : 1, host : "shard2:27022" }
    ]
  }
);
EOF


# 4. Инициализируем роутер

docker compose exec -T mongos_router1 mongosh --port 27017 --quiet <<EOF
sh.addShard("shard1/shard1:27021");
sh.addShard("shard2/shard2:27022");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
EOF
