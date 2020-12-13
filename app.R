## app.R ##
library(shiny)
library(shinydashboard)
library(highcharter)
library(reactable)

# Conditional color function
color_function <- function(value) {
  if (value > 0) {
    color <- "#008000"
  } else if (value < 0) {
    color <- "#e00000"
  } else {
    color <- "#777"
  }
  list(color = color, fontWeight = "bold")
}


# Server

server <- function(input, output) {
  
      # Winners table
      output$winners <- renderReactable({
        reactable(winners,
                  defaultPageSize = 10,
                  columns = list(
                    Last = colDef(format = colFormat(digits = 2)),
                    `+/- %` = colDef(style = color_function)
                    
                  ))
      })
      
      # Losers table
      output$losers <- renderReactable({
        reactable(losers,
                  compact = TRUE,
                  defaultPageSize = 10,
                  columns = list(
                    Last = colDef(format = colFormat(digits = 2)),
                    `+/- %` = colDef(style = color_function)
                    
                  ))
      })
      # Top Volume table
      output$top_vol <- renderReactable({
        reactable(top_vol,
                  compact = TRUE,
                  defaultPageSize = 10,
                  columns = list(
                    Last = colDef(format = colFormat(digits = 2)),
                    `+/- %` = colDef(style = color_function)
                    
                  ))
      })
      # Hot Stocks table
      output$hot_stock <- renderReactable({
        reactable(hot_stock,
                  compact = TRUE,
                  defaultPageSize = 10,
                  columns = list(
                    Last = colDef(format = colFormat(digits = 2)),
                    Ratio = colDef(style = color_function)
                    
                  ))
      })
      
      # OSEBX Price Plot
      output$hc3<-renderHighchart({
        hchart(benchmark_data, type = "ohlc") %>% 
        hc_add_theme(hc_theme_smpl())
      })
      
      
      # Stock list
      output$stock_list <- renderReactable({
        reactable(market_data,
                  
                  #Number of rows per page
                  defaultPageSize = 12,
                  
                  # Making the table searchable
                  searchable = TRUE,
                  
                  # Default sorting
                  defaultSorted = "Volume",
                  
                  # Column formatting
                  columns = list(
                    Last = colDef(format = colFormat(digits = 2)),
                    High = colDef(format = colFormat(digits = 2)),
                    Low = colDef(format = colFormat(digits = 2)),
                    Volume = colDef(defaultSortOrder = "desc",
                                    format = colFormat(digits = 0)),
                    
                    #Conditional formatting
                    
                    `+/- %` = colDef(style = color_function,
                    format = colFormat(percent = TRUE, digits = 2)),
                    
                    `+/- NOK` = colDef(style = color_function,
                                       format = colFormat(digits = 2))
                  )
        )
                    
                    
                    

                 
      })
      
      # Portfolio 
      output$my_portfolio <- renderReactable({
        reactable(my_portfolio,
                  columns = list(
                    `Profit (%)` = colDef(format = colFormat(digits = 2),
                                         style = color_function)))
      })

}

shinyApp(ui, server)