conf <- config::get()
con <- neo4j_api$new(
    url      = conf$url,
    user     = conf$username,
    password = conf$password
)

get_graph_components <- function(x) {
    
    query <-
        glue("MATCH (c:Company)-[r:invests_in]-(i:Investor) 
             WHERE c.name = '{x}' RETURN c, r, i;") %>%
        call_neo4j(con, type = "graph")
    
    nodes <- 
        unnest_nodes(query$nodes) %>%
        mutate(
            label = name,
            color.background = if_else(value == "Company", "salmon", "lightblue")
        ) %>% 
        select(id, label, color.background)
    
    rels <- 
        unnest_relationships(query$relationships) %>% 
        select(from = startNode, to = endNode) %>% 
        mutate(label = "")
    
    ## return 
    list(nodes = nodes, rels = rels)
}

remove_graph_components <- function(x, nn) {
    
    
    others <- glue_collapse(nn, "','")
    
    suppressMessages(
        res <- 
            glue(
                "WITH ['{others}'] as others
                 MATCH (c:Company {{name:'{x}'}})<-[r:invests_in]-(i:Investor)
                 OPTIONAL MATCH (i)-[:invests_in]->(o:Company)
                 WHERE o.name in others
                 WITH i, c, count(DISTINCT c) + count(DISTINCT o) as nods
                 WHERE nods = 1
                 RETURN i, c, nods;"
            ) %>%
            call_neo4j(con, type = "graph")
    )
    
    if(is_empty(res)) {
        res <- 
            glue("MATCH (c:Company) WHERE c.name = '{x}' RETURN c") %>% 
            call_neo4j(con, type = "graph")
    }
    # return
    res
}
