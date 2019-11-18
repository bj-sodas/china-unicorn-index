library(tidyverse)
library(shiny)
library(config)
library(httr)
library(neo4r)
library(visNetwork)
library(glue)

conf <- config::get()
# check if database is running
tryCatch(httr::GET(conf$url), 
         error = function(e) {"Database not up"})

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
                MATCH (c1:Company {{name:'{x}'}})<-[r:invests_in]-(i:Investor)
                OPTIONAL MATCH (i)-[:invests_in]->(c2:Company)
                WHERE c2.name in others
                WITH i, c1, count(DISTINCT c1) + count(DISTINCT c2) as nod
                WHERE nod = 1
                RETURN c1, i, nod;"
            ) %>%
            call_neo4j(con, type = "graph")
    )
    
    if(is_empty(res)) {
        res <- 
            glue("MATCH (c1:Company) WHERE c1.name = '{x}' RETURN c1") %>% 
            call_neo4j(con, type = "graph")
    }
    # return
    res
}


ui <- fluidPage(
    
    tags$h2("Hurun Chinese Unicorns"),
    
    sidebarLayout(
        sidebarPanel(
            width = 4,
            uiOutput("selection")
        ),
        mainPanel(
            width = 8,
            # tableOutput("text")
            visNetworkOutput("network", height = "1200px")
        )
    )
    
)

server <- function(input, output, session) {
    
    output$selection <- renderUI({
        
        companies <- "MATCH (c:Company) RETURN c.name" %>% 
            call_neo4j(con, type = "row") %>% 
            `[[`("c.name")
        
        selectInput("companies", "Select one or more company:", 
                    # remove default selection from choices
                    choices = companies[-1, ], multiple = TRUE)
    })
    
    # initial graph
    output$network <- renderVisNetwork({
        G <- get_graph_components(conf$inode)
        visNetwork(G$nodes, G$rels) %>% 
        visOptions(nodesIdSelection = TRUE)
        
    })
    
    # to make sure nodes and edges do not duplicate
    store <- reactiveVal()
    
    # update graph here
    observe({
        # insertion
        if (length(input$companies) > length(store())) {
            
            x <- setdiff(input$companies, store())
            message(paste("+", x))
            store(input$companies)
            
            G <- get_graph_components(x)
            
            visNetworkProxy("network") %>%
                visUpdateNodes(nodes = G$nodes) %>%
                visUpdateEdges(edges = G$rels)
        }
        
        # deletion
        if (length(input$companies) < length(store())) {
            
            x <- setdiff(store(), input$companies)
            message(paste("-", x))
            store(input$companies)
            
            if (is.null(store())) {
                # for the last node, else list is null returns nothing
                G <- remove_graph_components(x, conf$inode)
            } else {
                G <- remove_graph_components(x, c(store(), conf$inode))
            }
            
            ind <- map_chr(input$network_edges, pluck("to")) == G$nodes$id[G$nodes$label == "Company"]
            
            visNetworkProxy("network") %>%
                visRemoveNodes(id = G$nodes$id) %>% 
                visRemoveEdges(id = names(map_chr(input$network_edges, pluck("id"))[ind]))
        }
        
    })
    
    observe({
        store()
        visNetworkProxy("network") %>% visGetEdges()
    })
    
    
}

shinyApp(ui, server)

