library(shiny)
library(shinyjs)
library(shinydashboard)
library(plotly)
library(readr)

ui <- dashboardPage(
  dashboardHeader(title = "Performance Visualiser", titleWidth = "35%"),
  dashboardSidebar(sidebarMenu(
    id = "menuItems",
    menuItem(
      "Select OR Upload Log file",
      tabName = "SelectDS",
      icon = icon("th")
    ),
    menuItem(
      "System Performance",
      tabName = "sysdata",
      icon = icon("th")
    ),
    menuItem("Tabular Data", tabName = "TabularData", icon = icon("th"))
  )),
  dashboardBody(tabItems(
    tabItem(tabName = "SelectDS", h2("Upload Log file"),
            fluidRow(
              box(
                h3("Select CPU/Memory Log:"),
                selectInput("selip", "Select Uploaded CPU/Memory Log", c(
                  "", list.files(path = "./Uploads", include.dirs = FALSE)
                )),
                useShinyjs(),
                actionButton("selac", "Select File")
              ),
              box(
                h3("Upload CPU/Memory Log:"),
                fileInput(
                  'filecm',
                  'Select CPU/Memory Log to Upload',
                  accept = c('text/csv', 'text/comma-separated-values,text/plain', '.csv')
                ),
                useShinyjs(),
                actionButton("cmUpload", "Upload File")
              )
            )),
    tabItem(
      tabName = "sysdata",
      h2("CPU and Memory usage"),
      fluidRow(box(plotlyOutput("mem")),
               box(plotlyOutput("cm"))),
      fluidRow(box(width = "100%",
                   plotlyOutput("cpu")))
    ),
    tabItem(
      tabName = "TabularData",
      h2("Representation of Analysis Data in Tabular Format"),
      fluidRow(box(
        width = "100%",
        dataTableOutput('tableFormatData')
      ))
    )
  ))
)

server <- function(input, output, session) {
  cpudata <<- NULL
  
  listFiles <-
    c("", list.files(path = "./Uploads", include.dirs = FALSE))
  
  updateSelectInput(session, "selip", choices = listFiles)
  
  observeEvent(input$selac, {
    withProgress(message = 'CPU/Mem logs are being uploaded...', {
      tryCatch(
        if (input$selip != "")
        {
          cpudata <<- read_csv(paste0("./Uploads/", input$selip))
          updateTabItems(session, "menuItems", "sysdata")
        },
        error = function(e) {
          info(e)
        },
        warning = function(w) {
          info(w)
        }
      )
    })
  })
  
  observeEvent(input$cmUpload, {
    withProgress(message = 'CPU/Mem logs are being uploaded...', {
      tryCatch({
        inFile <- input$filecm
        file.copy(inFile$datapath, paste0("./Uploads/", inFile$name))
        listFiles <-
          c("", list.files(path = "./Uploads", include.dirs = FALSE))
        updateSelectInput(session, "selip", choices = listFiles)
      }, error = function(e) {
        info(e)
      }, warning = function(w) {
        info(w)
      })
    })
  })
  
  output$mem <- renderPlotly({
    input$selac
    input$cmUpload
    plot_ly(
      cpudata,
      x = Timestamp,
      y = Working_Set_GB,
      name = "Working Set(GB)",
      line = list(shape = "linear")
    ) %>%
      add_trace(
        x = Timestamp,
        y = Peak_Working_Set_GB,
        name = "Peak Working Set(GB)",
        line = (shape = "linear")
      ) %>%
      add_trace(
        x = Timestamp,
        y = Total_Memory_Used_GB,
        name = "Total Memory Used(GB)",
        line = (shape = "linear")
      ) %>%
      layout(xaxis = list(title = ""),
             yaxis = list(title = "Memory Usage(GB)"))
  })
  
  output$cm <- renderPlotly({
    input$selac
    input$cmUpload
    plot_ly(
      cpudata,
      x = Timestamp,
      y = Total_Memory_Used,
      name = "Memory Used(%)",
      line = list(shape = "linear")
    ) %>%
      add_trace(
        x = Timestamp,
        y = CPU_Usage,
        name = "CPU Usage(%)",
        line = (shape = "linear")
      ) %>%
      layout(xaxis = list(title = ""),
             yaxis = list(title = "System Usage(%)"))
  })
  
  output$cpu <- renderPlotly({
    input$selac
    input$cmUpload
    xd <- strsplit(as.character(cpudata$Cores_Usage), ";")
    y <- unlist(xd)
    xd3 <- matrix(y, ncol = length(xd[[1]]), byrow = TRUE)
    
    pString <-
      "coresPlot<-    plot_ly(
    cpudata, x = Timestamp, y = CPU_Usage, name = 'CPU Usage(%)', line = list(shape = 'linear'))"
    
    for (i in 1:ncol(xd3))
    {
      pString <-
        paste(
          pString,
          " %>% add_trace(x = Timestamp, y = ",
          eval(paste("xd3[,", i, "]", sep = "")),
          ", name='Core ",
          eval(paste(i, sep = "")),
          "(%)')",
          sep = ""
        )
      
    }
    pString <-
      paste0(pString,
             " %>%       layout(xaxis = list(title = ''), yaxis = list(title = 'CPU Usage(%)'))")
    eval(parse(text = pString))
    
    coresPlot
  })
  
  output$tableFormatData <-
    renderDataTable(options = list(scrollX = TRUE, pageLength = 10),
                    expr = {
                      input$selac
                      input$cmUpload
                      cpudata
                    })
}

shinyApp(ui, server)