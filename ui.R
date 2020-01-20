############## 0 ) INIT ##############

library("shiny")
library("shinyjs")
library("shinydashboard")
library("ggplot2")
library("plotly")
library("shinyBS")
library("visNetwork")
library("bnlearn")                                          #bayesian networks handler
library("gRain")                                            #bayesian networks visualizer
library("pbapply")                                          #adds progress bars to the apply family

source("scripts/utilities.R")                               #load utilities

##### 0.1 ) Input list #####

#     - nodeToQuery: list of all the nodes [SELECT]
#     - query: button to start a query on the selected node [ACTION BTN]
#     - nodeFlag: button to toggle the node details modal [ACTION BTN] (HIDDEN)
#     - dblClickFlag: 0 when a dblClick is detected, 1 otherwise [NUMERIC] (HIDDEN)
#     - clickFlag: 0 when a singleClick is detected, 1 otherwise [NUMERIC] (HIDDEN)
#     - clickDebug: counter that activates debug mode when it reaches 10 [NUMERIC] (HIDDEN)
#     - network: network container [PLOT]
#     - nodePlot: barplot with node distribution [PLOT]
#     - nodeModal: modal to show node details activated by nodeFlag [MODAL]
#     - queryModal: modal to show query details activated by query [MODAL]
#     - evidence: radio buttons listing all the values of the node [RADIOS]
#     - evidenceMenu: modal that shows the list of nodes and their values to set all the evidence at once [MODAL]
#     - evidenceMenuButton: button that opens the evidence menu modal [ACTION BTN]
#     - preTrained: button that loads a pre-trained BN [ACTION BTN]

##### 0.2 ) Custom Inputs #####

HTMLDownloadButton <- function(outputId, label = "Download", style){
  tags$a(id = outputId, class = "btn btn-default shiny-download-link", href = "", icon("globe"),
         target = "_blank", download = NA, NULL, label, style = style)
}

############## 1 ) UI ##############
#UI is a fluid page (reactive design) made of 3 components: Header, Sidebar and Body.

fluidPage(
  
  ##### 1.0 ) Stylesheets and libraries #####
  useShinyjs(),
  tags$link(href="bootstrap-tour-standalone.min.css",rel="stylesheet"),
  tags$script(src="bootstrap-tour-standalone.min.js"),
  tags$script(src="cookie.js"), #cookie handler
  theme = "appstyle.css", #custom css
  
  dashboardPage(
    title="ShinyDBNet",
    ##### 1.1 ) Header #####
    dashboardHeader(title = p("ShinyDBNet",tags$sup("Beta")),titleWidth = 350),
    
    ##### 1.2 ) Sidebar #####
    dashboardSidebar(
      width = 350,
      
      ##### 1.2.1 ) File Loading #####
      bsCollapse(id = "collapseLoad", open = "Learn The Network",
                 bsCollapsePanel("Learn The Network",
                                 div(id="fileInput2",fileInput(inputId =  "edgesFile", "Load edges",width = "95%", multiple = FALSE)),
                                 div(id="fileInput3",fileInput(inputId =  "dataFile", "Load data",width = "95%", multiple = FALSE)),
                                 actionButton(inputId = "preTrained", 
                                              class = "debugElement",
                                              label = "Load Example", 
                                              width = "86%")
                 )
      ),
      hr(),
      ##### 1.2.2 ) Query #####
      bsCollapse(id = "collapseQuery", open = "Network Inference",
                 bsCollapsePanel("Network Inference",
                                 div(id="querySection",
                                     selectInput(inputId = "nodeToQuery", 
                                                 label = "Node to query", 
                                                 choices = c(""),
                                                 selected = NULL, 
                                                 multiple = FALSE,
                                                 selectize = TRUE, 
                                                 width ="95%", 
                                                 size = NULL),
                                     actionButton(inputId = "query", 
                                                  label = "Query", 
                                                  width = "87%", 
                                                  icon = icon("brain"),
                                                  style = "background-color:orange; color:white"))
                 )
      ),
      hr(),
      actionButton(inputId = "evidenceMenuButton", 
                   label = " Evidence Panel", 
                   width = "87%", 
                   icon = icon("clipboard-list"),
                   style = "background-color:#4CAF50; color:white"),
      hr(),   
      actionButton(inputId = "multiPurposeButton", 
                   label = "Multi-purpose Debug Button", 
                   width = "87%", 
                   icon = icon("bug"),
                   style = "background-color:black; color:white"),
      div(id= "disclaimer", onclick = "Shiny.setInputValue('clickDebug', 0)",
          p(style="user-select: none", id="disclaimer-content","Powered by R-Shiny and Javascript"),
            tags$a(href = "https://github.com/detsutut/shinyDBNet", target="_blank", "Need help?")),
      
      ##### 1.2.3 ) Hidden Controls #####
      actionButton("nodeFlag",""),
      numericInput("dblClickFlag","",1),
      numericInput("clickFlag","",1),
      numericInput("clickDebug","",1),
      fileInput(inputId =  "bnUpload", "",width = "95%", multiple = FALSE)
    ),
    
    ##### 1.3 ) Body #####
    dashboardBody( 
      
      ##### 1.3.1 ) Main #####
      div(id= "loading", class = "loading",'Loading&#8230;'),
      visNetworkOutput("network", height = NULL, width = "110%"),
      fixedPanel(
        actionButton(inputId = "uploadBN",icon = icon("upload"), label = "upload BN",style = "background-color:#367FA9; color:white"),
        downloadButton(outputId ="downloadBN", label = "download BN",style = "background-color:#367FA9; color:white"),
        HTMLDownloadButton(outputId ="downloadHTML", label = "HTML",style = "background-color:#367FA9; color:white"),
        right = 50,
        top = 70,
        style = "background: rgba(150,150,180,0.2); padding: 10px; border-radius:15px"
      ),
      
      ## 1.3.2 ) Modals #####
      bsModal("nodeModal", 
              "Node Details", 
              "nodeFlag",
              size = "small",
              div(id= "loading2", class = "loading",'Loading&#8230;'),
              plotOutput("nodePlot"),
              radioButtons("evidence", "Evidence:",c(""))),
      bsModal("evidenceMenu", 
              "Evidence Menu", 
              "evidenceMenuButton",
              size = "big",
              uiOutput("evidenceControls")),
      bsModal("queryModal", 
              "Query Results", 
              "query",
              size = "big",
              div(id= "loading3", class = "loading",'Loading&#8230;'),
              plotOutput("queryPlot"),
              h4("Evidence details", align = "center"),
              tableOutput('evidenceTable'))
    )
  ),
  
  ##### 1.4 ) JS Scripts #####
  tags$script(src="init.js")
)