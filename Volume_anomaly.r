#install.packages("httr")
#install.packages("rvest")
#install.packages("quantmod")
#install.packages("tidyverse")
#install.packages("progress")
#install.packages("plotly")
#install.packages("ggthemes")
library(httr)
library(rvest)
library(quantmod)
library(tidyverse)
library(progress)
library(PerformanceAnalytics)
library(plotly)
library(ggthemes)


# PART 1: Web Scraping - Data from wikipedia -----------------------------

# To gather data about stocks listed on OSEBX we need a web scraping function. 
# Arguments: (1) The web-page url, (2) the CSS selector for the text we want
# Returns: Text of class 'character'
html_scraper <- function(url, CSS_selector) {
    output <- read_html(url) %>% 
        html_nodes(CSS_selector) %>% 
        html_text()
    return(output)
}

# Declare variables 
url = "https://en.wikipedia.org/wiki/List_of_companies_listed_on_the_Oslo_Stock_Exchange"
ticker_selector = "td+ td a:nth-child(2)" # CSS selector
company_selector = "td:nth-child(1)" # CSS selector

# Scrape the webpage
(osebx_tickers <- html_scraper(url, ticker_selector))
(osebx_companies <- html_scraper(url, company_selector))

# To increase the quality of our data we clean it. This functions uses regular 
# expressions to determine which characters to keep and removes everything else
# Arguments: a vector
# Returns: a vector
data_clean_strings <- function(vector) {
    vector <- str_replace_all(vector, "[^a-æøåêãçoàúüA-ÆØÅ0-9.-]", " ") %>% 
        trimws("r")
    return(vector)
}

(osebx_companies <- data_clean_strings(osebx_companies))

# For proper analysis we want to remove incomplete and irrelevant data. The
# function will remove empty observations
# Arguments: a vector
# Returns: a vector
data_remove_empty_elements <- function(vector) {
    set_without_empty_el <- vector[vector != ""]
    return(set_without_empty_el)
}

(osebx_companies <- data_remove_empty_elements(osebx_companies))

# Creating a tibble from the scraped data

(osebx_data_frame <- 
    list(Companies = osebx_companies, Tickers = osebx_tickers) %>% 
    as_tibble())


# PART 2: Fetching Stock Data ---------------------------------------------

# Declare variables
start_date <- Sys.Date() - 365 # First date of data to retrieve
end_date <- Sys.Date() # Last date of data to retrieve
Sys.setenv(TZ='UTC') # Changing the timezone
(yahoo_tickers <- osebx_data_frame$Tickers %>%
    paste(".OL", sep = ""))

# To get a stocks trading data we are using a wrapper called getSymbols
# getSymbols() is a part of the quantmod package that will request to download  
# data from the source we pass it (could be a csv file as well)
# Arguments: a ticker
# Returns: a xts object
load_stock_data <- function(ticker) {
    tryCatch({
        data <- getSymbols(Symbols = ticker, 
                           src = "yahoo", # Our source
                           index.class = "POSIXct", # Sets the class of the index
                           from = start_date, 
                           to = end_date,
                           adjust = TRUE, # Adjust prices for dividend payouts
                           auto.assign = FALSE 
        )},
        error=function(cond) {
            print(paste("Error downloading",ticker))
            return(NA)
        })
}

# To get the trading data for all stocks we loop through the tickers 
# and load it by using the load_stock_data() function. We wrap this in a
# tryCatch()function so that we can handle any errors that might occur when
# we download from yahoo finance
# Arguments: a vector of tickers
# Returns: a list of xts objects for each ticker
# Source for progress bar: https://github.com/tidyverse/purrr/issues/149

load_osebx_data <- function(tickers) {
    pb <- progress_estimated(length(yahoo_tickers))
    tickers %>%
        map(~{
            # update the progress bar (tick()) and print progress (print())
            pb$tick()$print()
            Sys.sleep(0.01)
            load_stock_data(.x)
        })
}

# Load the data
osebx_data <- load_osebx_data(yahoo_tickers)
head(osebx_data[[1]])

# Creat an empty tibble
osebx_volume_data <- tibble(
    company = character(),
    ticker = character(),
    last_volume = numeric(),
    avg_volume = numeric(),
    sd_volume = numeric(),
)

# To analyze the stock volumes we will create a tibble with some summary
# statistics and the last trading volume for each stock

for (i in seq_along(osebx_data)) {
    if (!is.na(osebx_data[[i]])) {
    stock_volume <- as_tibble(osebx_data[[i]]) %>%
        select(ends_with("Volume"))
    mean_volume <- round(mean(stock_volume[[1]], na.rm = TRUE),0)
    sd_volume <- round(sd(stock_volume[[1]], na.rm = TRUE),0)
    last_volume <- stock_volume %>%
        unlist() %>%
        last() -> last_volume
    osebx_volume_data <- osebx_volume_data %>%
        add_row(company = osebx_data_frame$Companies[i],
                ticker = osebx_data_frame$Tickers[i],
                last_volume = last_volume,
                avg_volume = mean_volume,
                sd_volume = sd_volume)
    }
}

(osebx_volume_data)


# PART 3: Identify Anomalies ----------------------------------------------

# To analyze volume anomalies we have to create some kind of indicator to look
# for. The user will be able to create an indicator when a stock's volume 
# exceeds a multiplier * standard deviation from the mean within the last day. In our model
# we've set it to 3. 
# Arguments: (1) a dataframe, (2) an integer
# Returns: a dataframe
add_sd_indicators <- function(dataframe,SD_multiplier) {
    dataframe <- dataframe %>%
        mutate(SD_multiplied = sd_volume * SD_multiplier)
    return(dataframe)
}

SD_multiplier <- 3
(indicator_set <- add_sd_indicators(osebx_volume_data,SD_multiplier))

# To see if the stocks volume exceeds the indicator we will create a signal 
# corresponding to True or False.
# Arguments: a dataframe
# Returns: a dataframe
add_sd_signals <- function(dataframe) {
    dataframe <- dataframe %>% 
        mutate(signal = ifelse(
                   last_volume > SD_multiplied + avg_volume,
                   TRUE,
                   FALSE)
        )
    return(dataframe)
}

(signal_set <- add_sd_signals(indicator_set))

# Finally we will use a function to filter out the observations where the signal
# is true. By doing this we will get a dataframe with stocks that have unusual
# high trading volume and their corresponding summary statistics.
# Arguments: (1) dataframe (2) an integer
# Returns: a dataframe
results <- function(dataframe) {
    results <- dataframe %>%
            filter(signal == T) %>%
            distinct()
    count <- nrow(results)
    if (count == 0) {
        return(cat("No stock's volume exceeds", SD_multiplier,"standard deviations"))
    } else {
        (cat(count,"stock(s) have unusual volume:\n\n"))
        return(results)
    }
}

(results <- results(signal_set))
# A simple graph will yield more information than some numbers. Therefore we
# will chart the time series data for the stocks that have unusual volume. 
# The quantmod package has an easy function chartSeries() to illustrate the 
# xts objects that we got from the getSymbols() wrapper. By showing the
# price movements and volume history together we get a clearer picture of how 
# the twofactors might correlate. 
# Arguments: (1) dataframe 
# Returns: financial charts
chart_volume_anomalies <- function(dataframe) {
    for (i in seq_along(1:nrow(dataframe))) {
        indices <- dataframe$company %>% 
            unlist() %>%
            match(osebx_data_frame$Companies)
        chart_name = paste(dataframe$company[i], " | ", dataframe$ticker[i])
        chartSeries(osebx_data[[indices[i]]],
                    name = chart_name,
                    theme = chartTheme('black',up.col='blue',dn.col='red'),
                    subset = "last 20 weeks"
                    )
    }
}

# Find stocks that have unusual volume and display corresponding charts
charts <- chart_volume_anomalies(results)


# Showing the historical Stock Price for the stocks with unusual volume
# Start of by naming the stocks with unusual volume as "selected_stocks".
# Then we create a vector that extracts the list number for
# the stocks with unusual volume.
selected_stocks <- results$company
indices <- selected_stocks%>% 
    unlist() %>% 
    match(osebx_data_frame$Companies)


# Then we create a for loop that creates a plot for every selected stock.
# By using the "plotly" library, the user can interact by hovering over 
# the graph of the historical stock prices and zoom in on the graph.
for (i in seq_along(1:length(indices))) {
    a <- osebx_data[[indices[i]]] %>% 
        na.omit() 
    a <-a[,4]
    plot <- autoplot(a) +
        geom_line(color ="turquoise4", size= 0.6)+
        geom_area(fill = "turquoise4", alpha = 0.6, size = 0.001) +
        ggtitle(paste("Time series data of",substr(colnames(a), 1, nchar(colnames(a))-9))) +
        labs(x = "Date", y = "Stock Price") +
        theme_economist_white() +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white",
                                              colour = "black",
                                              size = 0.1, linetype = 5),
              panel.grid.major = element_blank())
    plot <- ggplotly(plot)
    print(plot)
    
}


