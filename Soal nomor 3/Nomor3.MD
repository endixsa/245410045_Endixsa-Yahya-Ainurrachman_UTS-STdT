Tutorial ini menjelaskan cara membuat Streaming Replication PostgreSQL menggunakan Docker.

Prasyarat

Struktur Folder

docker-compose.yml

Konfigurasi Primary

Konfigurasi Replica

Membuat Script Replica dengan LF di Linux

Menjalankan Docker Compose

Memverifikasi Replikasi

Troubleshooting

Prasyarat

Docker Desktop terpasang
Download: https://www.docker.com/products/docker-desktop/

PowerShell atau CMD (disarankan, bukan Git Bash)

VS Code (untuk mengedit file dengan kontrol newline)

Struktur Folder

Buat folder project:

postgres-replication/
├── docker-compose.yml
├── primary/
│   ├── conf/
│   │   └── replication.conf
│   └── init/
│       └── 01-create-replication-user.sql
└── replica/
    ├── conf/
    │   └── replica.conf
    └── init/
        └── entrypoint-replica.sh   <-- script replikasi

docker-compose.yml
services:
  primary:
    image: postgres:15
    container_name: pg-primary
    environment:
      POSTGRES_PASSWORD: primarypass
    volumes:
      - ./primary/data:/var/lib/postgresql/data
      - ./primary/conf:/etc/postgresql/conf.d
      - ./primary/init:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"

  replica:
    image: postgres:15
    container_name: pg-replica
    environment:
      POSTGRES_PASSWORD: replicapass
    volumes:
      - ./replica/data:/var/lib/postgresql/data
      - ./replica/conf:/etc/postgresql/conf.d
      - ./replica/init:/docker-entrypoint-initdb.d
    ports:
      - "5433:5432"
    depends_on:
      - primary

Konfigurasi Primary
primary/conf/replication.conf
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
wal_keep_size = 512MB

primary/init/01-create-replication-user.sql
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicatorpass';

Konfigurasi Replica
replica/conf/replica.conf
hot_standby = on

Membuat Script LF di Linux

⚠ Penting (Windows Users): Script harus dibuat di Linux agar bebas CRLF/BOM.

Jalankan perintah ini dari PowerShell / CMD dalam folder project:

docker run -it --rm -v %CD%/replica/init:/init busybox sh


Di dalam shell Linux:

1. Hapus script lama
cd /init
rm -f entrypoint-replica.sh

2. Buat ulang script dengan LF murni
cat > entrypoint-replica.sh


Paste:

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


Simpan dengan:

CTRL + D

3. Buat executable
chmod +x entrypoint-replica.sh

4. Keluar
exit

Menjalankan Docker Compose
1. Hapus folder data replica (Wajib)
docker-compose down
rm -rf replica/data

2. Jalankan ulang
docker-compose up -d

3. Cek log replica
docker logs pg-replica

Waiting for primary...
Running base backup...
pg_basebackup: ... streamed write-ahead log ...

Memverifikasi Replikasi
1. Buat database & tabel di primary
docker exec -it pg-primary psql -U postgres

CREATE DATABASE testdb;
\c testdb
CREATE TABLE users(id SERIAL PRIMARY KEY, name TEXT);
INSERT INTO users(name) VALUES ('Alice'), ('Bob');

2. Cek di replica
docker exec -it pg-replica psql -U postgres -d testdb


Harus muncul data yang sama:

 id | name
----+-------
 1  | Alice
 2  | Bob

3. Cek status dari primary
docker exec -it pg-primary psql -U postgres -c "SELECT client_addr, state FROM pg_stat_replication;"


Output:

state = streaming

Troubleshooting
1. Replica menulis ulang cluster (initdb)

Jika log menunjukkan:

creating configuration files ... ok
running bootstrap script ... ok


=> Script tidak dieksekusi
=> Penyebab: CRLF / BOM / tidak executable / tidak termount

2. Script tidak bisa dijalankan

Error:

cannot execute: required file not found

Fix: buat script lewat BusyBox (lihat langkah LF).

3. Folder data replica tidak dihapus

Replica gagal base backup.
Fix: rm -rf replica/data
