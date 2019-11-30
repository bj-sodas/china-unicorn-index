FROM rocker/shiny-verse:3.6.1

RUN apt-get update && apt-get install -y \
	libjpeg62-turbo-dev \
	vim-tiny

RUN install2.r --error \
	--deps TRUE \
	--repos "https://mirror-hk.koddos.net/CRAN/" \
	shinydashboard \
    config \
    httr \
    visNetwork \
    glue \
    neo4r

COPY . /srv/shiny-server/china-unicorn-index

WORKDIR /srv/shiny-server/china-unicorn-index

EXPOSE 3838
