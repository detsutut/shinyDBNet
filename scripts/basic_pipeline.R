#Standard Pipeline

#Required Libraries
library("ggplot2")
library("plotly")
library("bnlearn")                                          
library("gRain")                                            
library("pbapply")  

setwd("D:\\Drive Lavoro\\2. Amc\\3. ADFICE-Bayes\\repositories\\shinyDBNet (PUBLIC)")
source(".\\scripts\\utilities.R")                                     #custom wrappers and functions
set.seed(42)

#Load Files
path.edges = ".\\data\\edges_rain_sprinkler.csv"
path.data = ".\\data\\\\data_rain_sprinkler.csv"
edges.string<-read.csv(file = path.edges, stringsAsFactors=FALSE)     #FROM-TO table with node names (needed for bnlearn)
data<-read.csv(file = path.data, stringsAsFactors=TRUE)               #Dataset with node names as columns (and nothing more)
nodes<-getNodes(edges.string)                                         #Table with nodes info
edges.id<-parseEdges(edges.string, nodes)                             #FROM-TO table with node ids (needed for visnet)

#Learn the DAG based on the FROM-TO table
#CYCLES NOT ALLOWED!
dag = dagtools.new(nodelist = nodes$label) %>%
  dagtools.fill(arcs_matrix = edges.string)
plot(dag)

#Learn the parameters (i.e. CPTs) from the data
bn = bn.fit(dag, data, method =  "bayes",iss = 1, debug = FALSE)     #Bayes = bayesian estimation

#Perform a conditional probability query
#Approximate inference
data.frame(No = cpquery(bn, (Cloudy == "No"), (Rain == "Yes")), 
           Yes= cpquery(bn, (Cloudy == "Yes"), (Rain == "Yes")), row.names = "Cloudy") 
#Exact inference
compile(as.grain(bn)) %>% setFinding(nodes = "Rain", states = "Yes") %>% querygrain(nodes = "Cloudy")

#Not satisfied with data-driven parameters for Rain --> manual change based on expert knowledge
cptRain = bn$Rain$prob
cptRain["No","No"] = 0.5       
cptRain["Yes","No"] = 0.5      #must sum to 1
cptRain["No","Yes"] = 0.4      
cptRain["Yes","Yes"] = 0.6     #must sum to 1
bn$Rain= cptRain
bn$Rain

#The same queries now give different results
#Approximate inference
data.frame(No = cpquery(bn, (Cloudy == "No"), (Rain == "Yes")), 
           Yes= cpquery(bn, (Cloudy == "Yes"), (Rain == "Yes")), row.names = "Cloudy") 
#Exact inference
compile(as.grain(bn)) %>% setFinding(nodes = "Rain", states = "Yes") %>% querygrain(nodes = "Cloudy")
