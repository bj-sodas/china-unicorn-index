library(tidyverse)
library(neo4r)
library(glue)
library(testthat)

source("global.R")

conf <- config::get()
# connect to database
con <- neo4j_api$new(
    url      = conf$url,
    user     = conf$username,
    password = conf$password
)
expect_equal(con$ping(), 200)

X1 = "Ant Financial"
X2 = "Didi Chuxing"

# add node
a <- get_graph_components(X1)
expect_equal(nrow(a$nodes), 4L)
expect_equal(nrow(a$rels),  3L)

# delete node
b <- remove_graph_components(X1, list(X2))
expect_equal(nrow(b$nodes), 3L)