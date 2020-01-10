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

############## 1 ) UI ##############
#UI is a fluid page (reactive design) made of 3 components: Header, Sidebar and Body.

UI <- fluidPage(
  
  ##### 1.0 ) Stylesheets and libraries #####
  useShinyjs(),
  tags$link(href="bootstrap-tour-standalone.min.css",rel="stylesheet"),
  tags$script(src="bootstrap-tour-standalone.min.js"),
  tags$script(src="cookie.js"), #cookie handler
  theme = "appstyle.css", #custom css
  dashboardPage(
    
    ##### 1.1 ) Header #####
    dashboardHeader(title = "Bayesian Network",titleWidth = 350),
    
    ##### 1.2 ) Sidebar #####
    dashboardSidebar(
      width = 350,
      
      ##### 1.2.1 ) File Loading #####
      bsCollapse(id = "collapseExample", open = "Load Files...",
                 bsCollapsePanel("Load Files...",
                                 div(id="fileInput1",fileInput(inputId =  "file1", "Load nodes",width = "95%", multiple = FALSE)),
                                 div(id="fileInput2",fileInput(inputId =  "file2", "Load edges",width = "95%", multiple = FALSE)),
                                 div(id="fileInput3",fileInput(inputId =  "file3", "Load data",width = "95%", multiple = FALSE)),
                                 actionButton(inputId = "preTrained", 
                                              class = "debugElement",
                                              label = "Load Pre-Trained BN", 
                                              width = "86%")
                 )
      ),
      hr(),
      
      ##### 1.2.2 ) Query #####
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
                    style = "background-color:orange; color:white")),
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
          p(style="user-select: none", id="disclaimer-content","Built with Shiny and Javascript - DEMO VERSION")),
      
      ##### 1.2.3 ) Hidden Controls #####
      actionButton("nodeFlag",""),
      numericInput("dblClickFlag","",1),
      numericInput("clickFlag","",1),
      numericInput("clickDebug","",1)
    ),
    
    ##### 1.3 ) Body #####
    dashboardBody( 
      
      ##### 1.3.1 ) Main #####
      div(id= "loading", class = "loading",'Loading&#8230;'),
      visNetworkOutput("network", height = NULL, width = "110%"),
      div(id= "divimage"),#, a(href="https://www.google.com/",img(class="logo", src = "src.png"))),
      
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

##### 2 ) SERVER #####

Server <- function(input, output, session) {
  
  ##### 2.1 ) On Server Start #####
  hide("preTrained")
  hide("nodeFlag")
  hide("dblClickFlag")
  hide("clickFlag")
  hide("clickDebug")
  hide('loading')
  hide("multiPurposeButton")
  checked = list(nodes=FALSE,edges=FALSE,data=FALSE)
  nodes = NULL
  edges = NULL
  data = NULL
  bn = NULL
  debug = FALSE
  debugCounter = 0
  evidenceMenuUiInjected = FALSE
  shinyjs::runjs(
    "if(getCookie('BN_tutorial') != 'true'){
        // Clear previous step
       localStorage.removeItem('tour_current_step');
       localStorage.removeItem('tour_end');
    
        // Initialize the tour
        tour.init();
    
    
        // Start the tour
        tour.start(true);
    }"
  )
  
  ## 2.2 ) Plots #####

  #' Plot the distribution of a target node.
  #' 
  #' @param withEvidence if evidence is set, prob is 0% 0% ... 100% ... 0% 0%
  #' @examples
  #' nodePlot(withEvidence = TRUE)
  nodePlot <- function(withEvidence = FALSE){
      if(!is.null(input$current_node_id)){
        nodeInfo = getNodeInfo(input$current_node_id)
        nodeName = nodeInfo$name
        if(withEvidence){
          choices = nodeInfo$choices[-1]
          prob = rep(0,length(choices))
          names(prob) = choices
          prob[nodeInfo$evidence]=1
        } else {
          s = table(rbn(bn, n = 5000, debug = FALSE)[nodeName])
          prob = s/sum(s)
        }
        barplot(prob/sum(prob),
                col = rainbow(n = length(prob), s = 0.5),
                main = toupper(nodeName),
                ylim=c(0,1))
      }
      hideLoading(modal=TRUE)
  }
  
  #' Plot the posterior distribution of a target query node.
  #' 
  #' @param data the outcoming probabilities of the query
  #' @examples
  #' queryData = table(cpdist(bn, queryNode, queryEvidence))
  #' queryPlot(data= queryData)
  #' @seealso \code{\link[bnlearn]{cpdist}} for the query data format
  queryPlot <- function(data){
    nodeInfo = getNodeInfo(nodes[which(nodes$label == input$nodeToQuery),]$id)
    s = table(rbn(bn, n = 5000, debug = FALSE)[nodeInfo$name])
    prob = s/sum(s)
    par(mfrow=c(1,2))
    barplot(prob/sum(prob),
            col = rainbow(n = length(prob), s = 0.5),
            ylim=c(0,1),
            main = paste("P(",toupper(input$nodeToQuery),")"))
    barplot(data/sum(data),
            col = rainbow(n = length(data), s = 0.5),
            ylim=c(0,1),
            main = paste("P(",toupper(input$nodeToQuery),"| EVIDENCE )"))
    hideLoading(query = TRUE)
  }
  
  ##### 2.3 ) Network #####

  #' Render the bayesian network. 
  #' Click and DblClick events chenge flags values triggering external actions.
  #' GravitationalConstant in \code{\link[visPhysics]{visPhysics}} can be changed to shrink/expand the network when rendering
  #' 
  #' @examples
  #' queryData = table(cpdist(bn, queryNode, queryEvidence))
  #' queryPlot(data= queryData)
  #' @seealso \code{\link[visNetwork]} for a detailed description of the rendering process
  visNetworkRenderer = function(){
    visNetwork(nodes, edges) %>%
      visNodes(shape = "ellipse") %>%
      visEdges(arrows = "to") %>%
      visOptions(collapse = FALSE, highlightNearest = FALSE) %>%
      visPhysics(stabilization = TRUE,
                 solver = "forceAtlas2Based",
                 forceAtlas2Based = list(gravitationalConstant = -40)) %>%
      visInteraction(navigationButtons = FALSE,dragView = TRUE) %>%
      visGroups(groupname = "evidence", color = "orange") %>%
      visEvents(doubleClick = "
        function(nodes) {
          Shiny.onInputChange('current_node_id', nodes.nodes);
          Shiny.setInputValue('dblClickFlag', 0)
          console.log(nodes.nodes)
        ;}",
                click = "
        function(nodes) {
          Shiny.onInputChange('current_node_id', nodes.nodes);
          Shiny.setInputValue('clickFlag', 0)
        ;}"    
      )
  }
  
  ##### 2.4 ) Observers #####
  
  #' When dblClickFlag value changes:
  #' Toggle the modal panel, update values of radio buttons with the values of the selected node and plot the distribution
  #' @seealso \code{\link{toggleModal}}, \code{\link{updateRadios}}, \code{\link{nodePlot}}, \code{\link{getNodeInfo}}
  observeEvent(input$dblClickFlag,{
    if(input$dblClickFlag == 0 && !is.null(input$current_node_id)) {
      showLoading(modal=TRUE)
      nodeInfo = getNodeInfo(input$current_node_id)
      toggleModal(session, 'nodeModal', toggle = 'toggle')
      updateRadios(id=input$current_node_id)
      output$nodePlot <- renderPlot({nodePlot(nodeInfo$evidenceYN)})
    } 
    updateNumericInput(session,"dblClickFlag",value = 1)
  })
  
  #' When clickFlag value changes:
  #' Update the selected node in the sidebar's query menu
  #' @seealso \code{\link{getNodeInfo}} 
  observeEvent(input$clickFlag,{
    if(input$clickFlag == 0 && !is.null(input$current_node_id)) {
      updateSelectInput(session,"nodeToQuery",selected = getNodeInfo(input$current_node_id)$name)
    }
    updateNumericInput(session,"clickFlag",value = 1)
  })
  
  #JUST FOR DEBUGGING
  observeEvent(input$multiPurposeButton,{
    ## Put here the code you want to check
    shinyjs::runjs("console.log(Shiny.inputBindings);")
  })
  
  #' When evidenceMenuButton is clicked:
  #' Update the selected node in the sidebar's query menu
  #' @seealso \code{\link{getNodeInfo}}, \code{\link{updateEvidence}}
  observeEvent(input$evidenceMenuButton,{
      lapply(1:length(nodes$id), function(i){
        id = nodes[i,]$id
        if(!evidenceMenuUiInjected){
        isolate({
          nodeInfo = getNodeInfo(id)
          insertUI(
            where = "beforeBegin",
            selector = "#evidenceControls",
            ui = tags$div(id="whocares",radioButtons(paste0("evidence_",id), label = toupper(nodeInfo$name), choices = nodeInfo$choices))
          )
        })}
        observeEvent(input[[paste0("evidence_",id)]],{
          updateEvidence(id,input[[paste0("evidence_",id)]])
        })
      })
    evidenceMenuUiInjected <<- TRUE
  })
  
  #' When clickDebug is clicked:
  #' increment the counter and activate/deactivate debug mode when counter goes up to 10
  #' @seealso \code{\link{getNodeInfo}}, \code{\link{updateEvidence}}
  observeEvent(input$clickDebug,{
    if(input$clickDebug == 0) {
      print(debugCounter)
      debugCounter <<- debugCounter+1
      updateNumericInput(session,"clickDebug",value = 1)
    }
    if(debugCounter==10) {
      if(!debug) {
        print("DEBUG MODE ENABLED")
        shinyjs::runjs("document.getElementById('disclaimer-content').innerHTML = 'Made by Buonocore T.M. [DEBUG MODE]'")
        show('preTrained')
        shinyjs::show("multiPurposeButton")
      }else{ 
        print("DEBUG MODE DISABLED")
        shinyjs::runjs("document.getElementById('disclaimer-content').innerHTML = 'Built with Shiny and Javascript - DEMO VERSION'")
        hide('preTrained')
        shinyjs::hide("multiPurposeButton")
        }
      debug <<- !debug
      debugCounter <<- 0
    }
  })
  
  #' When preTrained is clicked:
  #' load and render a pretrained bayesian network
  #' @seealso \code{\link{loadPreTrainedBN}}
  observeEvent(input$preTrained,{
    showLoading()
    bn <<- loadPreTrainedBN()
    updateSelectInput(session,"nodeToQuery",choices = nodes$label)
    output$network <- renderVisNetwork({visNetworkRenderer()})
    updateCollapse(session,id = "collapseExample", close = "Load Files...")
    hideLoading()
    shinyjs::runjs("tour.start(true);tour.goTo(6);")
  })
  
  #' When file1 is uploaded:
  #' read the csv, store the node info and update the sidebar's query menu
  #' if we already uploaded file2, we can render the network
  #' @seealso \code{\link{renderVisNetwork}}
  observeEvent(input$file1,{
    if(!is.null(input$file1)) {
      nodes<<-read.csv(file = input$file1$datapath,stringsAsFactors=FALSE)
      updateSelectInput(session,"nodeToQuery",choices = nodes$label)
    }
    checked$nodes <<- !is.null(input$file1)
    if(isRenderable()) {
      output$network <- renderVisNetwork({visNetworkRenderer()})
      shinyjs::runjs("tour.start(true);tour.goTo(4);")
    }
  })
  
  #' When file2 is uploaded:
  #' read the csv, store the edges info and update the sidebar's query menu
  #' if we already uploaded file1, we can render the network
  #' @seealso \code{\link{renderVisNetwork}} \code{\link{isRenderable}}
  observeEvent(input$file2,{
    if(!is.null(input$file2)) {
      edges<<-read.csv(file = input$file2$datapath,stringsAsFactors=FALSE)
    }
    checked$edges <<- !is.null(input$file2)
    if(isRenderable()) {
      output$network <- renderVisNetwork({visNetworkRenderer()})
      shinyjs::runjs("tour.start(true);tour.goTo(4);")
    }
  })
  
  #' When file3 is uploaded:
  #' read the csv, store the data and learn the bayesian network CPTs
  #' if we already uploaded file1 and file2, we can now query the network
  #' @seealso \code{\link{renderVisNetwork}} \code{\link{isQueriable}}
  observeEvent(input$file3,{
    if(!is.null(input$file3)) {
      data<<-read.csv(file = input$file3$datapath,stringsAsFactors=TRUE)
    }
    checked$data <<- !is.null(input$file3)
    if(isQueriable()) {
      bn<<-createBN(nodes,edges,data)
      updateCollapse(session,id = "collapseExample", close = "Load Files...")
      shinyjs::runjs("tour.start(true);tour.goTo(6);")
    }
  })

  #' When query is uploaded:
  #' retrieve the info 
  #' if we already uploaded file1 and file2, we can now query the network
  #' @seealso \code{\link{renderVisNetwork}} \code{\link{isQueriable}}    
  observeEvent(input$query,{
    showLoading(query = TRUE)
    evidenceIndices = which(nodes$group=="evidence")  #get the indices of the nodes where the evidence has been set
    evidenceNodes = nodes$label[evidenceIndices]      #get the names of the evidence nodes 
    evidenceStates = nodes$evidence[evidenceIndices]  #get the values of the evidence nodes
    if(length(evidenceIndices)==0){
      showNotification("No evidence set!")
      toggleModal(session, 'queryModal', toggle = 'toggle')
    } else {
      #dynamic querying is a bit tricky for cpdist. However, this approach has been suggested by the author of the package himself. 
      queryEvidenceString = paste("(", evidenceNodes, " == '",                         #build a set of node-value couples as a string
                  sapply(evidenceStates, as.character), "')",
                  sep = "", collapse = " & ")
      queryNodeString = paste("'", input$nodeToQuery, "'", sep = "")                   #query node as a string
      queryData = eval(parse(text = paste("table(cpdist(bn, ", queryNodeString, ", ",  #merge together and run the query
                                          queryEvidenceString, "))", sep = ""))) 
      output$queryPlot <- renderPlot({queryPlot(data= queryData)})
      output$evidenceTable <- renderTable(cbind(Nodes=toupper(evidenceNodes),Evidence=evidenceStates),width = '100%', align = 'c')
    }
  })
  
  #' When evidence radio buttons change:
  #' update di evidence
  #' @seealso \code{\link{updateEvidence}}
  observeEvent(input$evidence,{
    if(!is.null(input$current_node_id)){
      updateEvidence(input$current_node_id,input$evidence)
    }
  })
  
  ##### 2.5 ) Functions #####
  
  #' Check if nodes and edges of the network have been uploaded
  isRenderable = function(){
    condition_0 = (checked$nodes && checked$edges)
    condition_1 = FALSE
    if(condition_0){
      #consistency controls
      condition_1 = length(setdiff(unique(unlist(edges)),nodes$id))==0
    } 
    return(condition_0 && condition_1)
  }
  
  #' Check if nodes, edges and data have been uploaded
  isQueriable = function(){
    condition_0 = (checked$data && checked$nodes && checked$edges)
    condition_1 = FALSE
    if(condition_0){
      #consistency controls
      condition_1 = (length(setdiff(unique(unlist(edges)),nodes$id))==0) &&
        (length(setdiff(colnames(data),nodes$label))==0)
    } 
    return(condition_0 && condition_1)
  }
  
  #' Generate a Bayesian Network from the inputs.
  #' CPTs are learnt from the data. DAG is built combining nodes and edges info.
  #' 
  #' @param nodes the information about the nodes of the network
  #' @param edges the information about the edges of the network
  #' @param data the actual dataset from where to get the CPTs
  #' @return a bayesian network object, DAG included
  #' @examples
  #' nodes = read.csv("nodes.csv")
  #' edges = read.csv("edges.csv")
  #' data = read.csv("dataset.csv")
  #' bn = createBN(nodes,edges,data)
  createBN = function(nodes,edges,data){
    print("creating bn...")
    showLoading()
    edges_n = edges
    for(row in 1:nrow(edges_n)) {
      for(col in 1:ncol(edges_n)) {
        edges_n[row, col] = nodes[which(nodes$id==edges[row, col]),]$label
      }
    }
    dag = dagtools.new(nodelist = nodes$label) %>%
      dagtools.fill(arcs_matrix = edges_n)
    bn = bntools.fit(dag = dag,data = data)
    attr(bn,"dag") = dag
    hideLoading()
    return(bn)
  }
  
  #' Force rendered network refresh
  refreshNet = function(){
    visUpdateNodes(graph = visNetworkProxy('network', session = session), nodes = nodes)
  }
  
  #' Update the nodes table with new info and refreshes the net
  #' 
  #' @param id the id of the node to update
  #' @param evidence the value to set as evidence
  #' @examples
  #' updateEvidence(1,"male")
  #' @seealso \code{\link{setNodeInfo}}
  updateEvidence = function(id,evidence){
    setNodeInfo(id, evidence = evidence)
    if(evidence == "no_evidence"){
      setNodeInfo(id, evidenceYN = FALSE)
      output$nodePlot <- renderPlot({nodePlot(FALSE)})
    } else {
      setNodeInfo(id, evidenceYN = TRUE)
      output$nodePlot <- renderPlot({nodePlot(TRUE)})
    }
    refreshNet()
  }
  
  #' Update the radio buttons with the possible values of the target node
  #' 
  #' @param id the id of the target node
  updateRadios = function(id){
    nodeInfo = getNodeInfo(id)
    updateRadioButtons(session, "evidence",choices = nodeInfo$choices, selected = nodeInfo$evidence)
  }
  
  #' Hide the loading splashscreen
  #' 
  #' @param modal the splashscreen to hide is on a modal
  #' @param query the splashscreen to hide is on a query panel
  hideLoading = function(modal=FALSE, query = FALSE){
    if(modal) hideElement(id = 'loading2')
    else if(query) hideElement(id = 'loading3')
    else hideElement(id = 'loading')
  }
  
  #' Show the loading splashscreen
  #' 
  #' @param modal show the loading splashscreen on a modal
  #' @param query show the loading splashscreen on the query panel
  showLoading = function(modal=FALSE, query = FALSE){
    if(modal) showElement(id = 'loading2')
    else if(query) showElement(id = 'loading3')
    else showElement(id = 'loading')
  }
  
  #' Retrieve all the info the network has about the target node
  #' 
  #' @param targetNode the id of the target node
  #' @param verbose print the info
  #' @param byName targetNode is the name of the node instead of the id
  #' @return a list of properties of the target node
  #' @examples
  #' myNodeInfo = getNodeInfo(targetNode = "gender",byName = TRUE)
  getNodeInfo = function(targetNode, verbose = FALSE, byName = FALSE){
    if(byName){
      name = targetNode
      targetNode = nodes[which(nodes$label==targetNode),]$id
    }
    if(verbose) print(nodes[targetNode,])
    name = nodes[targetNode,]$label
    probs = bn[[as.character(name)]]$prob
    choices = c("no_evidence",rownames(probs))
    evidenceYN = (!is.na(nodes[targetNode,]$group) && nodes[targetNode,]$group == "evidence")
    evidence = nodes[targetNode,]$evidence
    return(list('name'=name, 'id' = targetNode, 'probs'=probs, 'choices'=choices, 'evidenceYN'=evidenceYN, 'evidence'=evidence))
  }
  
  #' Update target node's info.
  #' 
  #' @param targetNode the id of the target node
  #' @param name the name of the node. If NULL, not updated
  #' @param probs the probabilities of the node. If NULL, not updated
  #' @param evidenceYN the evidence flag of the node. TRUE/FALSE. If NULL, not updated
  #' @param evidence the selected value of the node. If NULL, not updated
  #' @examples
  #' setNodeInfo(1,name="gender", evidenceYN = TRUE, evidence = "male")
  setNodeInfo = function(targetNode, name=NULL, probs = NULL, evidenceYN=NULL, evidence=NULL){
    if(!is.null(name)) {
      nodes[targetNode,]$label <<- name
      if(!is.null(probs)) bn[[as.character(name)]]$prob <<- probs
    } else if(!is.null(probs)) bn[[as.character(nodes[targetNode,]$label)]]$prob <<- probs
    if(!is.null(evidenceYN)) {
      if(evidenceYN) nodes[targetNode,]$group <<- "evidence"
      else nodes[targetNode,]$group <<- "NA"
    }
    if(!is.null(evidence)) nodes[targetNode,]$evidence <<- evidence
  }
  
  #' Load a pretrained Bayesian Network, stored on the server.
  #' @return the bayesian network object
  loadPreTrainedBN = function(){
    nodes <<- read.csv(file = "data/nodes.csv",stringsAsFactors=FALSE)   
    edges <<- read.csv(file = "data/edges.csv",stringsAsFactors=FALSE)
    data <<- read.csv(file="data/data.csv",stringsAsFactors = TRUE)[-1]
    load(file = "data/bnFull")
    return(bn)
  }
  
}


shinyApp(ui = UI, server = Server)