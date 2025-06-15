 #!/bin/bash

echo "=== Checking Planka Container Networks ==="
echo

echo "1. All networks:"
docker network ls
echo

echo "2. Planka container details:"
docker inspect planka_planka_1 --format='{{range $net, $config := .NetworkSettings.Networks}}Network: {{$net}} | IP: {{$config.IPAddress}}{{end}}'
echo

echo "3. Postgres container details:"
docker inspect planka_postgres_1 --format='{{range $net, $config := .NetworkSettings.Networks}}Network: {{$net}} | IP: {{$config.IPAddress}}{{end}}'
echo

echo "4. All containers and their networks:"
docker ps --format "table {{.Names}}\t{{.Networks}}"