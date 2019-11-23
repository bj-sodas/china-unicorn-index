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

# add node
a <- get_graph_components("蚂蚁金服")
expect_equal(nrow(a$nodes), 4L)
expect_equal(nrow(a$rels),  3L)

# delete node
b <- remove_graph_components("蚂蚁金服", list("滴滴出行"))
expect_equal(nrow(b$nodes), 3L)