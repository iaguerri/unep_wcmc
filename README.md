# unep_wcmc

## Set up with docker-compose :whale:

>NOTE: to install this environment both [docker](https://docs.docker.com/get-docker/) and [docker-compose](https://docs.docker.com/compose/) are required

1. Build with docker-compose build

```bash
docker-compose build
```

2. Start the corresponding containers with docker-compose up

```bash
docker-compose up
```

Bring only jupyter service up

```bash
docker-compose up jupyter
```

3. Access the link to access Jupyter within the notebooks directory.

To access the database through `psql` you could run the following,

- Open a new terminal in the postgres container

```bash
docker exec -it env_postgres_1 /bin/bash
```

- Access the database via psql

```bash
docker exec -it env_postgres_1 psql -U postgres
```
