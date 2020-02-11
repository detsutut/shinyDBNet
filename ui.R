############## 0 ) INIT ##############
version = "1.0.1"

library("shiny")
library("shinyjs")
library("shinydashboard")
library("ggplot2")
library("plotly")
library("dplyr")
library("shinyBS")
library("visNetwork")
library("bnlearn")                                          #bayesian networks handler
library("gRain")                                            #bayesian networks visualizer
library("pbapply")                                          #adds progress bars to the apply family
library("DT")

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

HTMLDownloadButton <- function(outputId, label = "Download", style, title = ""){
  tags$a(id = outputId, title = title, class = "btn btn-default shiny-download-link", href = "", icon("image"),
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
    dashboardHeader(title = p(tags$img(src="bn_w.png", height ="25px"),"ShinyDBNet",tags$sub(tags$i("ADFICE-IT"))),titleWidth = 350),
    
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
      hr(style="border-top-color:rgba(0,0,0,.1"),
      ##### 1.2.2 ) Query #####
      bsCollapse(id = "collapseQuery", open = "Network Inference",
                 bsCollapsePanel("Network Inference",
                                 div(id="querySection",
                                     selectInput(inputId = "nodeToQuery", 
                                                 label = "Selected node", 
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
                                                  style = "background-color:#1cb7a0; color:white"),
                                     actionButton(inputId = "viewCPT", 
                                                  label = "CPT Viewer",
                                                  icon = icon("edit"),
                                                  width = "87%", 
                                                  style = "background-color:#63adfc; color:white"),
                                     actionButton(inputId = "evidenceMenuButton", 
                                                  label = " Evidence Panel", 
                                                  width = "87%", 
                                                  icon = icon("clipboard-list"),
                                                  style = "background-color:#fd6f71; color:white")
                                     )
                                 
                 )
      ),
      hr(style="border-top-color:rgba(0,0,0,.1"), 
      actionButton(inputId = "multiPurposeButton", 
                   label = "Multi-purpose Debug Button", 
                   width = "87%", 
                   icon = icon("bug"),
                   style = "background-color:black; color:white"),
      div(id= "disclaimer", onclick = "Shiny.setInputValue('clickDebug', 0)",
          p(style="user-select: none; color: #C2BCB7", id="disclaimer-content","Funded by"),
          tags$a(href="https://www.zonmw.nl/nl/", target="_blank", img(class="logo", src = "zonmw.png", width = "50%")),
          ),
      hr(style="border-top-color:rgba(0,0,0,.1"),
      div(p(style="user-select: none; color: #C2BCB7; text-align:center",paste0("Software version ",version))),
      
      ##### 1.2.3 ) Hidden Controls #####
      actionButton("nodeFlag",""),
      actionButton("arcsFlag",""),
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
        actionButton(inputId = "uploadBN",icon = icon("upload"), title="upload Bayesian Network", label = "",style = "background-color:#367FA9; color:white"),
        downloadButton(outputId ="downloadBN", title="download Bayesian Network", label = "",style = "background-color:#367FA9; color:white"),
        HTMLDownloadButton(outputId ="downloadHTML", title="Open image as HTML", label = "",style = "background-color:#367FA9; color:white"),
        actionButton(inputId = "help",icon = icon("info"), title = "Need help?", label = "",style = "background-color:#367FA9; color:white"),
        right = 40,
        top = 60,
        style = "background: rgba(150,150,180,0.2); padding: 10px; border-radius:15px"
      ),
      div(id= "divimage", a(href="https://www.amsterdamumc.nl/",img(class="logo", src = "umc.png"))),
      
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
              size = "small",
              uiOutput("evidenceControls")),
      bsModal("arcsMenu", 
              "Arcs Suggestions Menu", 
              "arcsFlag",
              size = "small",
              p("Undeclared potential relationships emerged from the data. Do you want to include them in the network?"),
              checkboxGroupInput("arcsCheckboxes", "Suggested Arcs:", choices = NULL, selected = NULL,
                                 inline = FALSE, width = NULL, choiceNames = NULL,
                                 choiceValues = NULL),
              p("Check the arcs that you want to keep. Remaining arcs will be ignored."),
              actionButton("createWithArcs","update the Network",style = "background-color:#63adfc; color:white")),
      bsModal("cptModal", 
              "CPT Viewer", 
              "viewCPT",
              size = "big",
              DT::dataTableOutput("mytable")),
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