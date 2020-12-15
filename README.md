# Shiny-Dashboard-App-Oslo-Stock-Exchange
Important: To run the full project and see the app, download the "BAN400 - Full Project.RMD" file and run all the chunks! (might need to install some packages first)

About the project:
This Shiny Dashboard app gives daily updates about the Oslo Stock Exchange and the option to plot historical prices of stocks. 
The app uses web scraping to get the ticker names for the stocks listed on OSEBX. 
Stock data is fetched from Yahoo Finance using the Quantmod/BatchGetSymbols library. 
The app is made interactive using the Reactable and Highcharter libraries.

Progression:
The project started out with the file "Volume_Anomaliy.R" where we web scraped ticker names from wikipedia, fetched the stock data from Yahoo Finance and
created a signal for stocks with unusual volume. However, as the wikipedia page lacked a lot of ticker names and we wanted to create a Shin Dashboard app with different content
, we started over and created the file "BAN400 - Exam.RMD". After days of trying to find APIs and web scraping JS pages like oslobors.no, euronext.com using RSelenium and PhantomJS, we
found a page we easily could web scrape ticker and company names from. Our script now get ticker and company names from gurufocus.com, which is updated every time a new stock is added.
Daily updated data is fetched from Yahoo Finance and stored in a tidyer way than before, using BatchGetSymbols. Further we started building the content for the webpage and created a
script for the Shiny Dashboard app ("app.R") and the frontend ("ui.R").

To make it easier to see the result, we merged all the files into one called "BAN400 - Full Project.RMD".

For the future:
We have learned a lot from programming this app, and will continue to add more features in the future. 
Our plan is to add a portfolio manager, portfolio metrics (beta, alpha, sharpe), backtesting investment strategies 
and more visualizations!
