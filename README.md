## China Unicorn Index

```
#R #Shiny #Neo4j #Docker
```

#### Background

An application built on `Shiny` which integrates with `Neo4j` graph database. Data is extracted from Hurun.net, which published an index of China unicorns (company with more than 10 billions in valuation).

[English url](https://www.hurun.net/EN/HuList/Unilist?num=ZUDO23612EaU) |
[Chinese url](http://www.hurun.net/CN/HuList/Unilist?num=ZUDO23612EaU)

#### Build Docker Image

```bash
docker build -t . china-unicorn-index .
```

*Note: Replace [CRAN mirror url](https://cran.r-project.org/mirrors.html) with the one that is closest to you.*


#### Run App (Local Method)

Start a [Neo4j Docker](https://hub.docker.com/_/neo4j) container with the following options,

* ports 7474 (HTTP) and 7687 (Bolt) exposed;
* binds the import directory (so that we can import data through csv files);
* create username (**neo4j**) and password (**somepassword**) for authentication;

```bash
docker run \
    --name china-unicorn-index \
    -p7474:7474 -p7687:7687 \
    -d \
    -v $PWD/Graph/Data:/var/lib/neo4j/import \
    --env NEO4J_AUTH=neo4j/somepassword \
    neo4j:3.5.13
```

With Docker up and running, we import our data by passing [queries](Graph/setup.cql) through `bin/cypher-shell`.

```bash
cat Graph/setup.cql |  docker exec --interactive china-unicorn-index bin/cypher-shell -u neo4j -p somepassword
```

Database is ready. Run the application in `RStudio`, or on command line type,

```bash
R -e 'Shiny::runApp(host="127.0.0.1", port=31234)'
```
*Note: You must have required packages installed.*

Open your web browser and locate http://localhost:31234.
