library(tidyverse)
library(shiny)
library(neo4r)
library(visNetwork)

con <- neo4j_api$new(
    url = "http://localhost:7474",
    user = "neo4j",
    password = "1234"
)
con$ping()

get_graph_components <- function(x) {
    
    init <-
        sprintf("MATCH (c:Company)-[r:invests_in]-(i:Investor) WHERE c.name = '%s' RETURN c, r, i;", x) %>%
        call_neo4j(con, type = "graph")
    
    nodes <- 
        unnest_nodes(init$nodes) %>%
        mutate(
            label = name,
            color.background = if_else(value == "Company", "salmon", "lightblue")
        ) %>% 
        select(id, label, color.background)
    
    rels <- 
        unnest_relationships(init$relationships) %>% 
        select(from = startNode, to = endNode) %>% 
        mutate(label = "")
    
    ## return 
    list(nodes = nodes, rels = rels)
}


ui <- fluidPage(
    
    tags$h2("Hurun Chinese Unicorns"),
    
    sidebarLayout(
        sidebarPanel(
            width = 2,
            uiOutput("selection")
        ),
        mainPanel(
            width = 10,
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
        
        G <- get_graph_components("蚂蚁金服")
        visNetwork(G$nodes, G$rels)
        
    })
    
    # to make sure nodes and edges do not duplicate
    store <- reactiveVal()
    
    # update graph here
    observe({
        
        # insertion
        if (length(input$companies) > length(store())) {
            
            store(input$companies)
            message(paste("+", last(store())))
            
            G <- get_graph_components(last(store()))
            visNetworkProxy("network") %>%
                visUpdateNodes(nodes = G$nodes) %>%
                visUpdateEdges(edges = G$rels)
        }
        
        # deletion
        if (length(input$companies) < length(store())) {
            
            x <- setdiff(store(), input$companies)
            store(input$companies)
            message(paste("-", x))
            
            G <- get_graph_components(x)
            visNetworkProxy("network") %>%
                visRemoveNodes(id = G$nodes$id) %>%
                visRemoveEdges(id = G$nodes$id)
            
        }
        
    })
    
    
}

shinyApp(ui, server)

