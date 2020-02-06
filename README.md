# ShinyDBNet Documentation

This open-source Shiny application provides an **interactive framework for learning, visualizing and reasoning with Discrete Bayesian Networks** (DBNs), a type of probabilistic graphical model that uses Bayesian inference for probability computations.

*This documentation assumes that the reader is already familiar with of Bayesian Networks. If not so, a gentle introduction to the main concepts of Bayesian Networks can be found [here](https://machinelearningmastery.com/introduction-to-bayesian-belief-networks/), along with some further readings.*

<p align="center">
  <img src="src/screenshot.png" alt="Application preview" width="100%"/>
  <p align ="center"><small>Application preview</small></p>
</p>

## Summary

1) [Getting Started](https://github.com/detsutut/shinyDBNet#getting-started)
    * [Running the App](https://github.com/detsutut/shinyDBNet/#running-the-app)
    * [Learning the Bayesian Network](https://github.com/detsutut/shinyDBNet/#learning-the-bayesian-network)
    * [Loading the Bayesian Network](https://github.com/detsutut/shinyDBNet/#loading-and-downloading-the-bayesian-network)
    * [Querying the Network](https://github.com/detsutut/shinyDBNet/#querying-the-network)
2) [Example: the Asia dataset](https://github.com/detsutut/shinyDBNet/#example-the-asia-dataset)
3) [Built With](https://github.com/detsutut/shinyDBNet/#built-with)
4) [FAQ](https://github.com/detsutut/shinyDBNet/#faq)
5) [Authors](https://github.com/detsutut/shinyDBNet/#authors)
6) [License](https://github.com/detsutut/shinyDBNet/#license)

## Getting Started

### Running the App

You can run the app from [here](https://detsutut.shinyapps.io/shinyDBNet/) or from your local machine. 

For the latter approach, you first need to initialize the directory you want to use as the app container with `git init`, then you have to move into that folder and run the following command to clone the repository onto your local machine:
```
git clone https://github.com/detsutut/shinyDBNet.git
```
This will get you a running copy of the most recent version of `shinyDBNet`.
In order to run the app, you must first open your R/RStudio console and install all of its dependencies:
```
install.packages(c("shiny",
                  "shinyjs",
                  "shinydashboard",
                  "ggplot2",
                  "plotly",
                  "shinyBS",
                  "visNetwork",
                  "bnlearn",
                  "gRain",
                  "pbapply")) 
```
You can now run the app simply as follows:
```
shiny::runApp("your/path/to/the/app/directory")
```
This will start a local instance on your default browser. 
You can also start the app directly from the github repository running:
```
shiny::runGitHub('shinyDBNet', 'detsutut')
```

### Learning the Bayesian Network

In order to learn the DBN, two files must be uploaded. These files describes the network in terms of its nodes (i.e. variables), its edges (i.e. relationships between variables) and the data from which to learn the conditional probability tables (i.e. the dataset you're interested in learning from). The conditional probability tables (CPTs) are learnt using posterior Bayesian estimation arising from a flat, non-informative prior \[Nagarajan et al., 2013\].

<p align="center">
  <img src="src/learnthenetwork.png" alt="network learning panel" width="40%"/>
  <p align ="center"><small>Network Learning Panel</small></p>
</p>

Files have to be in \*.csv format and must follow this templates:

* Edges: the directed connections between the nodes of the network

  | from | to  |
  | ---- | --- |
  | Cloudy    | Sprikler   |
  | Cloudy    | Rain   |
  | Sprikler   | Wet Grass   |
  | Rain    | Wet Grass   |

* Data: the entries from which to learn the conditional probability tables (CPTs)

  | Cloudy | Sprikler | Rain | Wet Grass |
  | ------ | -------- | ---- | --------- |
  | Yes    | No       | Yes  | Yes       | 
  | No     | No       | No   | No        | 
  | No     | Yes      | No   | Yes       | 
  
**IMPORTANT: the names of the Edges entries and the names of the Data columns must coincide.**

### Loading and downloading the Bayesian Network

If you already learnt your DBN, you can also upload it directly into the app using the `upload BN` button from the panel on the top-right side. 
In the same way, the currently displayed DBN can be downloaded as an R object through the `download BN` button.

If you only want to share the visual representation of your DBN, without allowing any editing, you can use the `HTML` button to download the canvas as an HTML page. Right click and "save image as..." will do the trick if you want a PNG file instead.

<p align="center">
  <img src="src/downloadpanel.png" alt="download/upload panel" width="40%"/>
  <p align ="center"><small>Download/Upload Panel</small></p>
</p>

If you don't have a pre-trained DBN to load and no data to learn from, you can play with a **pre-trained example** by clicking the `Load Example` button. This will upload a network for evaluating car insurance risks, which is detailedly described [here](https://www.bnlearn.com/documentation/man/insurance.html).

### Querying the Network

Click on the nodes to see their prior distributions, where you can also set the evidence for the target node. If multiple evidence has to be set, you may consider using the `Evidence Panel` to manage it quickly.

When you're done with the evidence setting, select the node you want to query and use the sidebar panel to perform the query and see how the distribution changes.

<p align="center">
  <img src="src/networkinference.png" alt="network inference" width="40%"/>
  <p align ="center"><small>Query Panel</small></p>
</p>

The metod used to perform this conditional probability queries it logic sampling, used to generate random samples conditional on the evidence. More information on logic sampling can be found [here](https://www.bnlearn.com/documentation/man/cpquery.html).

## Example: the Asia dataset

Here we will learn a DBN from a small synthetic data set \[Lauritzen and Spiegelhalter, 1988\] about lung diseases (tuberculosis, lung cancer or bronchitis) and visits to Asia. This example can be found on Scutari's [bnlearn webpage](https://www.bnlearn.com/documentation/man/asia.html) too.

Lauritzen and Spiegelhalter (1988) describe it as follows:

“*Shortness-of-breath (dyspnoea) may be due to tuberculosis, lung cancer or bronchitis, or none of them, or more than one of them. A recent visit to Asia increases the chances of tuberculosis, while smoking is known to be a risk factor for both lung cancer and bronchitis. The results of a single chest X-ray do not discriminate between lung cancer and tuberculosis, as neither does the presence or absence of dyspnoea.*”

<p align="center">
  <img src="src/asiaDAG.png" alt="Directed Acyclig Graph representation of Lauritzen and Spiegelhalter problem" width="50%"/>
  <p align ="center"><small>Directed Acyclig Graph (DAG) representation of Lauritzen and Spiegelhalter problem</small></p>
</p>

We might then be interested in answer some questions about how these variables interact with eachother, as for instance:
* How does knowing that the subject took a `ChestXRay` scan in the last year influences our guessing on `Dyspnoea`?
* How do the chances of having `Dyspnoea` change if we also know that the patient has neither `Tubercolosis` nor `Lung Cancer`?
* How does smoking affect the probabilities of having a `Lung Cancer` or `Bronchitis`? Does it affect `Tubercolosis` as well?

In order to anser these questions, we must learn the Discrete Bayesian Network. Thus, the two files mentioned in [Learning the Bayesian Network](https://github.com/detsutut/shinyDBNet/#learning-the-bayesian-network) must be loaded first (you can find them in the data folder).

Once the network is learnt and rendered, we can start inferencing our model to answer the previous questions. Let's first set `ChestXRay = YES` by clicking on the node and checking the radio button.

<p align="center">
  <img src="src/evidence.png" alt="setting the evidence on the ChestXRay node" width="60%"/>
  <p align ="center"><small>Setting the evidence on the ChestXRay node</small></p>
</p>

After setting the evidence on the observed node, we can perform a conditional probability query on the node of interest, in this case `Dyspnoea`.

<p align="center">
  <img src="src/dyspnoeaquery.png" alt="conditional probability query on Dyspnoea" width="90%"/>
  <p align ="center"><small>Conditional probability query on Dyspnoea</small></p>
</p>

As shown in the figure above (A.), we can assess that knowing a patient has gone under a chest X-ray scan increases the probability of having dyspnoea. 

Querying other nodes of the network under the same evidence set, we can clearly see that the reason of this increment is due to the association between `ChestXRay`, `LungCancer` and `Tubercolosis`: if a patient undergoes a chest X-ray, chances are that he's doing it because he has `Tubercolosis` or `LungCancer`, which have a direct influence on the `Dyspnoea` value.

Setting a negative evidence on both the `Tubercolosis` and the `LungCancer` nodes (B.) therefore "cancels out" the effect of `ChestXRay` restoring a distribution very close to the prior. Remember that you can use the `Evidence Menu` to set the evidence on multiple nodes quickly.

Let's see how being a smoker influences `Lung Cancer`, `Bronchitis`, and `Tubercolosis`.

<p align="center">
  <img src="src/querySmoking.png" alt="conditional probability query on Lung Cancer, Bronchitis and Tubercolosis" width="100%"/>
  <p align ="center"><small>Conditional probability query on Bronchitis (A.), Lung Cancer (B.) and Tubercolosis (C.)</small></p>
</p>

In all the three queries, being a smoker increases the chances of having the desease, but with different magnitudes.

## Built With

* [R](https://www.r-project.org/) - Main Language
* [SHINY](https://shiny.rstudio.com/) - Used to build the interactive web app straight from R
* [BNLEARN](https://www.bnlearn.com/) - Main depencency of the project, used to learn and query the bayesian network
* [VISNETWORK](https://datastorm-open.github.io/visNetwork/) - For network visualization
* [SHINYAPPS.IO](http://shinyapps.io/) - RStudio servers where the webapp is hosted

## FAQ

* **Why the posterior distribution of the queried node is zero?** *Logic sampling, the method currently implemented for conditional probability queries, is a form of rejection sampling. Therefore, only the obervations matching evidence (out of the n that are generated) are returned, and their number depends on the probability of evidence. If the evidence you set doesn't mach any of your observations, then the number of generated samples will be zero.*
  
* **After setting the evidence, the distribution of the queried node doesn't change. Why?** *There are several scenarios in which this may happen. First, check that the distributions you are seeing come from the `Query Results` panel and not from the `Node Details` one (where you can only see the prior distributions). If the panel you are checking is correct, then the variable(s) you set might not influence the target or your query, or their overall influence might be cancelled out by the single components. Check the [example](https://github.com/detsutut/shinyDBNet#example-the-asia-dataset) to see how it happens.*

* **Querying the same node multiple times, under the same evidence set, gives me different distributions. Why?** *Queries are performed using approximate inference methods based on Monte-Carlo Particle Filters. Some variability in the results is threfore expected since they are Monte Carlo estimates. If the variability in the results is too high, then your evidence is likely to have a very low probability (i.e. very complex query) and you need to generate more particles to obtain a reasonably precise estimate of that conditional probability. Unfortunately, the number of particles to generate is not user-defined at the moment.*

## Future Developments

* Make CPTs manually editable
* Add support for latent variables
* Exact inference for relatively simple networks
* Nodes and arcs interactive add/removal
* DAG import from DAGitty
* Detect cycles in the DAGs and propose possible trimmings to address the problem
* Data-driven arcs suggestions

## Authors

* **Tommaso Buonocore** - *Author and Repository Maintainer* - [GitHub](https://github.com/detsutut), [LinkedIn](https://www.linkedin.com/in/tbuonocore/)

## Acknowledgements
We thank ZonMw for funding, along with the UMC's departments of Geriatrics and Medical Informatics and the ADFICE-IT/CAREFREE teams.

## License

This project is licensed under the AGPLv3 License - see the [LICENSE.md](LICENSE.md) file for details

<p align="center">
  <img src="https://www.gnu.org/graphics/agplv3-with-text-162x68.png" alt="AGPLv3" width="15%"/>
</p>
