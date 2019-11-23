library(tidyverse)
library(shiny)
library(config)
library(httr)
library(neo4r)
library(visNetwork)
library(glue)
source("global.R")

ui <- fluidPage(
    
    tags$h2("Hurun Chinese Unicorns"),
    
    sidebarLayout(
        sidebarPanel(
            width = 4,
            uiOutput("selection")
        ),
        mainPanel(
            width = 8,
            visNetworkOutput("network", height = "1200px")
        )
    )
    
)

server <- function(input, output, session) {
    
    output$selection <- renderUI({
        
        companies <- "MATCH (c:Company) RETURN c.name" %>% 
            call_neo4j(con, type = "row") %>% 
            `[[`("c.name")
        
        selectInput(
            "companies", "Select one or more company:",
            # remove initial selection from choices
            choices = subset(companies, value != conf$inode),
            multiple = TRUE
        )
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

