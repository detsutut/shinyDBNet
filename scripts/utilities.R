##### BN Utilities #####


#' Create a fully-specified bayesian network. There must be correspondence between the names of DAG's nodes and the names of the variables in the dataset.
#' 
#' @param dag the DAG of the network
#' @param data the data used to estimate distributions
#' @param method method used for parameters estimation (only "bayes" available at the moment)
#' @param priorWeight the higher, the more important the prior is (and the less influent data observations are)
#' @param verbose if TRUE, prints the network
#' @return fully-specified bayesian network
#' @examples 
bntools.fit = function(dag, data,method=c("bayes"),priorWeight = 1, verbose = FALSE){
  bn = bn.fit(dag, data = data, method =  method,iss = priorWeight, debug = verbose) 
  if(verbose) print(bn)
  return(bn)
}

#' Query a target node given some evidence on other nodes, comparing the probability distribution of the target node before and after conditioning on the given evidence.
#' 
#' @param bn the fully-specified bayesian network to query
#' @param target target node of the query
#' @param evidenceNodes nodes where the evidence is set
#' @param evidenceStates values of the evidence
#' @return table with the results of the query
#' @examples bntools.query(bn,target = "A", evidenceNodes = c("B","C"), evidenceStates = c("b1","c2"))
bntools.query = function(bn, target = NULL, evidenceNodes = c(), evidenceStates = c()){
  junction_tree = compile(as.grain(bn))
  if(is.null(target)) target = select.list(nodes(bn), preselect = NULL,  multiple = FALSE,  title = "Query target node:", graphics = TRUE)
  if(length(evidenceNodes)==0){
    selected = select.list(setdiff(nodes(bn), target), 
                           preselect = NULL, 
                           multiple = TRUE,
                           title = "Set evidence on:",
                           graphics = TRUE)
    for(node in selected){
      evidenceNodes = c(evidenceNodes,node)
      levels = dimnames(bn[[node]]$prob)[[node]]
      if(is.null(levels)) levels = dimnames(bn[[node]]$prob)[[1]]
      state = select.list(levels, 
                          preselect = NULL, 
                          multiple = FALSE,
                          title = paste(toupper(node),"observed:"),
                          graphics = TRUE)
      evidenceStates = c(evidenceStates,state)
    }
  }
  junction_tree_evidence = setEvidence(junction_tree, nodes=evidenceNodes, states = evidenceStates)
  queries = cbind(querygrain(junction_tree,nodes = target)[[target]], 
                  querygrain(junction_tree_evidence,nodes = target)[[target]])
  colnames(queries) = c(paste("P(",toupper(target),")",collapse = ""),paste("P(",toupper(target),"| Evidence* )",collapse = ""))
  barplot(queries, 
          main=paste(toupper(target),"distributions"),
          sub = paste("*Evidence :",paste(evidenceNodes,"=",evidenceStates,collapse = ", ")),
          ylab="Probability",
          legend = rownames(queries),
          col = rainbow(n = length(rownames(queries)), s = 0.5),
          args.legend = list(x = "bottomright", cex=0.8, title = toupper(target)),
          beside=TRUE, horiz=FALSE)
  tryCatch(shinyjs::hideElement(id = 'loading3'),error = function(e) print(e))
  # return(queries)
}

#' Check if two nodes are d-separated given some evidence on other nodes. If no evidence is given, a greedy search will look for all the possible combination of nodes that, 
#' when given, d-separate the source node and the target node. On complex network where the greedy search would be computationally expensive, the user may set the maximum subset
#' size to explore. If the maximum subset size is negative, the algorithm will stop when the minimum subset of d-separating features is detected.
#' 
#' @param bn the bayesian network to explore
#' @param source source node
#' @param target target node
#' @param given evidence
#' @param maxSize maximum subset size
#' @param verbose if TRUE, DAG is plotted. Default FALSE.
#' @return boolean if evidence is given, list of the d-separating combinations otherwise
#' @examples result = dagtools.dsep(dag,source="A", target="C", maxSize = -2)
bntools.dsep = function(bn, source=NULL, target=NULL, given = NULL, maxSize = NULL) {
  autobreak = FALSE
  dag = attr(bn,"dag")
  if(is.null(source)) source = select.list(nodes(dag), 
                                           preselect = NULL, 
                                           multiple = FALSE,
                                           title = paste("Select Node 1:"),
                                           graphics = TRUE)
  if(is.null(target)) target = select.list(setdiff(nodes(dag), source), 
                                           preselect = NULL, 
                                           multiple = FALSE,
                                           title = paste("Select Node 2:"),
                                           graphics = TRUE)
  cat("looking for sufficient adjustment sets between",toupper(source),"and",toupper(target),"...\n")
  if(path(bn, source, target, direct = TRUE)) return(list())
  if (is.null(given)) {
    nodesToCheck = setdiff(nodes(dag), c(source, target))
    allCombos = lapply(
      seq_len(length(nodesToCheck)),
      FUN = function(x)
        combn(x = nodesToCheck, x)
    )
    positiveCombos = list()
    if(is.null(maxSize)) maxSize = length(nodesToCheck)
    else if(maxSize<0){ maxSize = abs(maxSize)
    autobreak = TRUE
    } 
    allCombos = allCombos[which(lapply(allCombos,nrow)<=maxSize)]
    for (comboList in allCombos) {
      results = pbapply(comboList, 2, function(z) {
        dsep(dag,
             x = source,
             y = target,
             z = unlist(z))
      })
      positive = comboList[, which(results == TRUE)]
      if (is.matrix(positive) && ncol(positive) > 0) {
        for (i in 1:ncol(positive))
          positiveCombos = append(positiveCombos, list(unlist(positive[, i])))
      }
      else if (length(positive) > 0)
        positiveCombos = append(positiveCombos, list(unlist(positive)))
      if(autobreak && length(positiveCombos)>0) break
    }
    return(positiveCombos)
  } else return(dsep(dag, x=source, y=target, z=given))
}

##### DAG Utilities #####

#' Create a new dag from scratch. Nodes can be passed as an argument or interactively generated.
#' 
#' @param nodelist list of node names. If NULL, nodes will be generated via command line prompt
#' @return dag with no arcs
#' @examples dag = dagtools.new(nodelist = list("A","B","C","D"))
dagtools.new = function(nodelist = NULL) {
  if (is.null(nodelist)) {
    nodelist = list()
    repeat{
      n <- readline(prompt="Enter the name of the new node (leave empty to exit): ")
      if(n=="") break
      nodelist = c(nodelist,n)
    }
  }
  dag = empty.graph(unlist(nodelist))
  return(dag)
}

#' Fill the empty dag with arcs. Arcs can be passed as an argument or interactively generated.
#' 
#' @param dag the empty dag where the nodes of the network have already been instantiated.
#' @param arcs_matrix matrix of all the arcs of the network. If NULL, arcs will be generated asking the user to provide information about the parents of each node of the network.
#' @param verbose if TRUE, print the arcs matrix 
#' @return fully-specified dag
#' @seealso dagtools.new
#' @examples dag = dagtools.new(nodelist = list("A","B","C","D"))
#'           arcs = matrix(c("A", "B", 
#'                           "A", "C",
#'                           "C", "D"),
#'                         byrow = TRUE, ncol = 2,
#'                         dimnames = list(NULL, c("from", "to")))
#'           dag = dagtools.fill(dag, arcs_matrix = arcs)              
dagtools.fill = function(dag, arcs_matrix = NULL,verbose=FALSE) {
  if (is.null(arcs_matrix)) {
    arcs_matrix = matrix(
      nrow = 0,
      ncol = 2,
      byrow = TRUE,
      dimnames = list(NULL, c("from", "to"))
    )
    nodes = names(dag$nodes)
    parentsCheck = matrix(TRUE,
                          nrow = length(nodes),
                          ncol = length(nodes),
                          byrow = TRUE,
                          dimnames = list(nodes, nodes)
    )
    diag(parentsCheck) = rep(FALSE, length(nodes))
    for (row in length(nodes):1) {
      child = nodes[row]
      validParentsInd = which(
        parentsCheck[row,])
      validParents = nodes[validParentsInd]
      parents = select.list(validParents, 
                            preselect = NULL, 
                            multiple = TRUE,
                            title = paste("Parents of", toupper(child),":"),
                            graphics = TRUE)
      parentsCheck[parents, row] = FALSE
      for(parent in parents){
        arcs_matrix = rbind(arcs_matrix, c(parent, child))
      }
    }
  }
  if(verbose) print(arcs_matrix)
  arcs(dag) = arcs_matrix
  return(dag)
}

#' Fill the empty dag with arcs. Arcs are learned from the data using bootstrap. Blacklist and whitelist can be used to force/negate relashionships between nodes.
#' There must be correspondence between the names of the network's nodes and the variables of the dataset.
#' 
#' @param x the data used to learn the structure of the network
#' @param nboot number of bootstrap samples
#' @param bl blacklist (optional)
#' @param wl whitelist (optional)
#' @param dag expert DAG to visualize for comparison purposes
#' @param verbose if TRUE, DAG is plotted. Default FALSE.
#' @seealso dagtools.fill
#' @return fully-specified dag
#' @examples dag = dagtools.new(nodelist = list("A","B","C","D")) 
#'           dag_learned = dagtools.learn(x = mydataset,
#'                                        nboot = 100, 
#'                                        dag = dag, 
#'                                        bl=matrix(c("A", "C","C", "A"), ncol = 2, byrow = TRUE),
#'                                        verbose = TRUE)
dagtools.learn = function(x, nboot = 100, bl = NULL, wl = NULL, dag = NULL, verbose = FALSE){
  if(!is.null(wl)) dimnames(wl)[[2]] = c("from","to")
  if(!is.null(bl)) dimnames(bl)[[2]] = c("from","to")
  if(!is.null(dag)){
    strength = arc.strength(dag, data = x, criterion = "x2")
    rbind(wl, strength[which(strength$strength>0.05),1:2]) #whitelisting the arcs reported by the expert but not well supported by the data (p-value bigger than 0.05)
  }
  bootstrappedNets = boot.strength(x, R = nboot, algorithm = "tabu",algorithm.args = list(whitelist = wl, blacklist = bl))
  plot(bootstrappedNets)
  abline(v = 0.25, col = "tomato", lty = 2, lwd = 2)
  abline(v = 0.50, col = "tomato", lty = 2, lwd = 2)
  abline(v = 0.75, col = "tomato", lty = 2, lwd = 2)
  dag_learned = averaged.network(bootstrappedNets)
  if(verbose) dagtools.plot(dag_learned,title=c("Data-driven DAG","Expert-driven DAG"),compareWith = dag)
  return(dag_learned)
}

#' Check if two nodes are d-separated given some evidence on other nodes. If no evidence is given, a greedy search will look for all the possible combination of nodes that, 
#' when given, d-separate the source node and the target node. On complex network where the greedy search would be computationally expensive, the user may set the maximum subset
#' size to explore. If the maximum subset size is negative, the algorithm will stop when the minimum subset of d-separating features is detected.
#' 
#' @param dag the DAG to explore
#' @param source source node
#' @param target target node
#' @param given evidence
#' @param maxSize maximum subset size
#' @param verbose if TRUE, DAG is plotted. Default FALSE.
#' @return boolean if evidence is given, list of the d-separating combinations otherwise
#' @examples result = dagtools.dsep(dag,source="A", target="C", maxSize = -2)
dagtools.dsep = function(dag, source=NULL, target=NULL, given = NULL, maxSize = NULL) {
  autobreak = FALSE
  if(is.null(source)) source = select.list(nodes(dag), 
                                           preselect = NULL, 
                                           multiple = FALSE,
                                           title = paste("Select Node 1:"),
                                           graphics = TRUE)
  if(is.null(target)) target = select.list(setdiff(nodes(dag), source), 
                                           preselect = NULL, 
                                           multiple = FALSE,
                                           title = paste("Select Node 2:"),
                                           graphics = TRUE)
  cat("looking for sufficient adjustment sets between",toupper(source),"and",toupper(target),"...\n")
  if (is.null(given)) {
    nodesToCheck = setdiff(nodes(dag), c(source, target))
    allCombos = lapply(
      seq_len(length(nodesToCheck)),
      FUN = function(x)
        combn(x = nodesToCheck, x)
    )
    positiveCombos = list()
    if(is.null(maxSize)) maxSize = length(nodesToCheck)
    else if(maxSize<0){ maxSize = abs(maxSize)
    autobreak = TRUE
    } 
    allCombos = allCombos[which(lapply(allCombos,nrow)<=maxSize)]
    for (comboList in allCombos) {
      results = pbapply(comboList, 2, function(z) {
        dsep(dag,
             x = source,
             y = target,
             z = unlist(z))
      })
      positive = comboList[, which(results == TRUE)]
      if (is.matrix(positive) && ncol(positive) > 0) {
        for (i in 1:ncol(positive))
          positiveCombos = append(positiveCombos, list(unlist(positive[, i])))
      }
      else if (length(positive) > 0)
        positiveCombos = append(positiveCombos, list(unlist(positive)))
      if(autobreak && length(positiveCombos)>0) break
    }
    return(positiveCombos)
  } else return(dsep(dag, x=source, y=target, z=given))
}

#' Look for all the couples that are made conditionally independent by the input evidence
#' 
#' @param dag the DAG to explore
#' @param given evidence
#' @return list of node pairs
#' @examples result = dagtools.findIc(dag, given = c("A","C"))
dagtools.findIc = function(dag, given = NULL) {
  if(is.null(given)) given = select.list(nodes(dag), 
                                         preselect = NULL, 
                                         multiple = TRUE,
                                         title = paste("Select Given Nodes:"),
                                         graphics = TRUE)
  nodesToCheck = setdiff(nodes(dag), given)
  combos = combn(x = nodesToCheck, 2)
  positiveCombos = list()
  results = pbapply(combos,2,function(x){
    dsep(dag,x=x[1],y=x[2],z=given)
  })
  if(length(which(results==TRUE))==0) return(NULL)
  a = combos[,which(results==TRUE)]
  b=list()
  for (i in 1:ncol(a))
    b = append(b, list(unlist(a[, i])))
  return(b)
}

#' Plot a DAG. An additional DAG can be passed for comparison.
#' 
#' @param dag the DAG to plot
#' @param title title(s) of the plot
#' @param compareWith second DAG to compare with (optional)
#' @examples result = dagtools.plot(dag, title = c("Expert DAG","DAG from Data"),compareWith = dag_learned)
dagtools.plot = function(dag, title = c("",""), compareWith = NULL){
  output = NULL
  if(!is.null(compareWith)){
    par(mfrow = c(1,2))
    output = graphviz.compare(dag,compareWith,shape = "rectangle", main = title)
    legend(x="bottomright",50,legend=c("Different", "Missing"),
           col=c("red", "blue"), lty=1:2, cex=0.4) 
    par(mfrow=c(1,1))
  }
  else graphviz.plot(dag, shape = "rectangle", main = title[1]) 
  return(output)
}


