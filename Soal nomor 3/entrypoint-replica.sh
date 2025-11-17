#!/bin/sh
set -e

if [ -s /var/lib/postgresql/data/PG_VERSION ]; then
  exec docker-entrypoint.sh postgres
fi

echo "Waiting for primary..."
until pg_isready -h primary -p 5432 -U postgres; do
  sleep 1
done

echo "Running base backup..."
PGPASSWORD=primarypass pg_basebackup -h primary -D /var/lib/postgresql/data -U replicator -Fp -Xs -P -R

chown -R postgres:postgres /var/lib/postgresql/data

exec docker-entrypoint.sh postgres
