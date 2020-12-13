library(shiny)
library(shinydashboard)
library(reactable)

ui <- dashboardPage(
  # Theme color
  skin = "purple",
  
  # Header
  dashboardHeader(title = "Stockmate"),
  
  # Sidebar content
  dashboardSidebar(sidebarMenu(
    menuItem("Dashboard", tabName = "dashboard", icon = icon("landmark")),
    menuItem("My portfolio", tabName = "portfolio", icon = icon("hand-holding-usd"))
    )),
  
  # Body content
  dashboardBody(
    tabItems(
      
      # Dashboard content
      tabItem(tabName = "dashboard",
              h2("Market overview"),
              
              
              tabBox(width = 12,
                     
              # Market Overview tab
              tabPanel("Market Overview",
              fluidRow(
                   column(4, width = 12,
                        h3 ("Oslo Stock Exchange"),
                        highchartOutput("hc3"))),
              fluidRow(
                  column(4, 
                         width = 6,
                         length = 5,
                         h3("Winners"),
                         reactableOutput('winners')),
                  column(6, 
                         width = 6,
                         length = 5,
                         h3("Losers"),
                         reactableOutput('losers'))),
              fluidRow( 
                  column(4,
                         width = 6,
                         length = 5,
                         h3("Most Bought"),
                         reactableOutput('top_vol')),
                  column(6, 
                         width = 6,
                         length = 5,
                         h3("Hot Stock - Abnormal volume"),
                         reactableOutput('hot_stock')))),
            
              # Stock List tab
              tabPanel("Stock List",
                       fluidRow(
                         column(4,
                                width = 12,
                                reactableOutput('stock_list'))
                       ))
              
              
              )),

    # Portfolio content
    tabItem(tabName = "portfolio",
            h2("My portfolio"),
            fluidRow(
              column(4,
                     width = 12,
                     reactableOutput('my_portfolio'))
    )
    )
  )
  )
)



