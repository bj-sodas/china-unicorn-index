library(tidyverse)
library(ggthemes)
library(RSelenium)
library(rvest)

# ggplot theme
old <- theme_set(theme_tufte() + theme(text = element_text(family = 'Menlo')))
url <- "https://www.hurun.net/EN/HuList/Unilist?num=ZUDO23612EaU"

# using Docker
remDr <- remoteDriver(
    remoteServerAddr = "localhost",
    port = 4445L,
    browserName = "firefox"
)
remDr$open()

# navigate to page
remDr$navigate(url)
pages <- remDr$findElements("css", ".page-number")

# translate column names
colnms <-
    c(
        "ranking",
        "valuation",
        "company",
        "key_person",
        "headquarter",
        "industry",
        "investors"
    )

# parse table into tibble
get_ranking <- function(x) {
    x %>% 
        unlist() %>% 
        read_html() %>% 
        html_node(css = "#mytable") %>% 
        html_table() %>% 
        as_tibble(.name_repair = ~ colnms)
}


# do for all pages
tbls <- map(1:length(pages), ~ {
    # locate element
    tblElems <- remDr$findElement(using = "css", 
                                  value = "table#mytable.table.table-hover.table-striped")
    # extract html 
    xml <- tblElems$getPageSource()
    # extract table
    res <- get_ranking(xml)
    # go to next page
    nxt <- remDr$findElement("css", ".page-next a")
    nxt$clickElement()
    Sys.sleep(3)
    # return
    res
})


# Tidy Data ---- 

raw_dat <- bind_rows(tbls)

# companies' list
companies <- raw_dat %>% 
    mutate(valuation = str_extract(valuation, "\\d+"),
           company   = str_remove(company, "^\\s|\\s$")) %>% 
    select(ranking:industry)

# investors' list
investors <- raw_dat %>% 
    select(company, investors) %>% 
    separate(investors, into = paste0("c", 1:5), sep = ",", fill = "right") %>% 
    gather(ind, investor, -company, na.rm = TRUE) %>% 
    select(-ind) %>% 
    mutate(company   = str_remove(company, "^\\s|\\s$"),
           investor  = str_remove(investor, "^\\s|\\s$"))

# export data
write_csv(companies, "import/companies.csv")
write_csv(investors, "import/investors.csv")


# close Selenium driver
remDr$closeServer()
