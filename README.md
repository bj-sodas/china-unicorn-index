## China Unicorn Index

```
#R #Shiny #Neo4j #Docker
```

#### Background

An application built on `Shiny` which integrates with `Neo4j` graph database. Data is extracted from Hurun.net
([English](https://www.hurun.net/EN/HuList/Unilist?num=ZUDO23612EaU) |
[Chinese](http://www.hurun.net/CN/HuList/Unilist?num=ZUDO23612EaU)),
which published an index of China unicorns (company with more than 10 billions in valuation).

The purpose of this exercise is to provide a demonstration of **connecting R to graph database**, and package exploratory tool into **viable data product**.

#### Build Docker Image

```bash
docker build -t . china-unicorn-index .
```

*Note: Replace [CRAN mirror url](https://cran.r-project.org/mirrors.html) with the one that is closest to you.*

#### Configuration

We are required to create a config file named `config.yml` in your directory. It is used for Shiny app to locate Neo4j database and authentication information.

```yaml
default:
    title:      # Something that displays on application title bar
    url:        # Neo4j database and port e.g http://172.30.10.9:7474
    username:   # Neo4j username
    password:   # Neo4j password
    inode:      # Initial node to display
```

#### Run App ( with `Docker Compose` )

We will [define](docker-compose.yml) and run 2 services, one for our Neo4j database (named `neo4j`) and one for our Shiny app (named `webapp`).

First we extract the database snapshot to `Graph` folder so that data can be pre-populated.

```bash
tar -xvzf graph.db.tar.gz -C Graph
```

Then we specify the configuration as the following,

```yaml
default:
    title: China Unicorn Index
    url: neo4j:7474
    username: neo4j
    password: somepassword
    inode: 蚂蚁金服
```

On command line run

```bash
docker-compose up
```

Open your web browser and locate http://localhost:3838/china-unicorn-index.

#### Run App ( from local `runApp` )

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

Database is ready. Here we specify the configuration as the following,

```yaml
default:
    title: China Unicorn Index
    url: http://127.0.0.1:7474
    username: neo4j
    password: somepassword
    inode: 蚂蚁金服
```

Run the application in `RStudio`, or on command line run

```bash
R -e 'Shiny::runApp(host="127.0.0.1", port=33838)'
```
*Note: You must have required packages installed in your local station.*

Open your web browser and locate http://localhost:33838.
