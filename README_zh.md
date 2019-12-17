![Banner](banner.png)

Language: **[ENG](README.md) 🇬🇧 | [中文](README_zh.md)** 🇨🇳

# 中国独角兽指数

```
#R #Shiny #Neo4j #Docker
```

<img src="demo.gif" alt="drawing" width="480"/>

## 背景

这是一个基于 `R` + `Shiny`、由 `Docker` 封装、 并融入 `Neo4j` 图形数据库的网页应用。
数据来自胡润报告发布的大中华区独角兽指数（[英文](https://www.hurun.net/EN/HuList/Unilist?num=ZUDO23612EaU) |
[中文](http://www.hurun.net/CN/HuList/Unilist?num=ZUDO23612EaU)）。独角兽定义为估值在10亿美金以上的公司。
这个练习的目的是提供一个 Demo 用来演示 **如何在R环境中连接图形数据库** 以及 **将EDA工具封装成数据产品**。

## 安装

#### 建立 Docker 镜像

```bash
git clone https://github.com/bj-sodas/china-unicorn-index.git
cd china-unicorn-index
## 注：更换 CRAN mirror url (https://cran.r-project.org/mirrors.html) 为离你最近的地址以提高下载速度  ---
docker build -t china-unicorn-index .
```

也可以选择从 Github 镜像仓直接下载

```bash
docker pull docker.pkg.github.com/bj-sodas/china-unicorn-index/china-unicorn-index:latest
```

#### 配置

为了帮助 `Shiny` 定位 `Neo4j` 数据库及认证信息，你需要在文件夹目录下生成一个名为 `config.yml` 的配置文件。这里附上了[配置文件样本](config.yml.sample)供你产考。

```yaml
default:
    title:      # Something that displays on application title bar
    url:        # Neo4j database and port e.g http://172.30.10.9:7474
    username:   # Neo4j username
    password:   # Neo4j password
    inode:      # Initial node to display
```

## 启动应用

我们提供了两种启动应用的方法，其中我们推荐使用 `docker-compose` ([I](#i-run-app--with-docker-compose-)) 。配置文件已为你定义个别应用服务，启动即可；如果有特别需要，你也可以分开启动 `docker` 和 `shiny` ([II](#ii-run-app--from-local-runapp-))。

#### (I) 启动 APP ( 使用 `Docker Compose` )

这里[定义](docker-compose.yml)两个服务, 一个是为 Neo4j 数据库（名为 `neo4j-db`）另一个是 Shiny app（名为 `webapp`）。


首先将数据库的快照放入 `Graph` 文件夹中完成数据预填充。

```bash
tar -xvzf graph.data.tar.gz -C Graph
```

接下来将配置明确如下：

```yaml
default:
    title: China Unicorn Index
    url: http://neo4j-db:7474 # docker will resolve address of neo4j
    username: neo4j
    password: somepassword
    inode: 蚂蚁金服
```

然后在命令行执行：

```bash
# make sure you are in 'china-unicorn-index' base directory
docker-compose up -d
```

最后打开浏览器，进入 http://localhost:33838/china-unicorn-index 即可。

#### (II) 启动 APP ( 在本地执行 `runApp` )


首先通过如下设置启动一个 [Neo4j Docker](https://hub.docker.com/_/neo4j) (名为 **neo4j-db**) 容器：

* 指定 7474（HTTP）和 7687（Bolt）为对外端口；
* 联通数据输入路径（从而使数据库可以读入 csv 文件）；
* 创建用户名（**neo4j**）和密码（**somepassword**）用于认证;

```bash
# make sure you are in 'china-unicorn-index' base directory
docker run \
    --name neo4j-db \
    -p7474:7474 -p7687:7687 \
    -d \
    -v $PWD/import:/var/lib/neo4j/import \
    --env NEO4J_AUTH=neo4j/somepassword \
    neo4j:3.4.0
```


启动 Docker 后，把[查询语句](Graph/setup.cql)传输至 `bin/cypher-shell` 从而获取数据。

```bash
cat Graph/setup.cql |  docker exec --interactive neo4j-db bin/cypher-shell -u neo4j -p somepassword
```

现在数据库已经准备好了，接下来我们将配置明确如下：

```yaml
default:
    title: China Unicorn Index
    url: http://127.0.0.1:7474 # neo4j is exposed to localhost
    username: neo4j
    password: somepassword
    inode: 蚂蚁金服
```

在 `RStudio` 中启动应用，或者在命令行执行：

```bash
R -e 'shiny::runApp(host="127.0.0.1", port=33838)'
```
*注: 你需要将必要的 R 包安装到本地。*

最后打开浏览器，进入 http://localhost:33838 即可.

#### FAQ

我的应用无法启动，报错信息显示 `An error has occurred. Check your logs or contact the app author for clarification` 。


* 请检查你的配置文件，是否正确声明了数据库url地址？
* `neo4j` 需要一定时间启动，请刷新浏览器。
