# shinyDBNet

shinyDBNet is a Shiny application that provides an interactive framework for reasoning with Discrete Bayesian Networks.

## Getting Started

You can run the app from [here](https://detsutut.shinyapps.io/shinyDBNet/) or from your local machine. Follow the instruction in [Development, Testing and Deployment](https://github.com/detsutut/shinyDBNet#development-testing-and-deployment) for the latter approach.

### Loading the network

In order to load the network, three files must be uploaded. These files describes the network in terms of its nodes, its edges and the data from which to learn the CPTs.
Files have to be in \*.csv format and must follow this templates:

* Edges: the directed connections between the nodes of the network

  | from | to  |
  | ---- | --- |
  | Cloudy    | Sprikler   |
  | Cloudy    | Rain   |
  | Sprikler   | Wet Grass   |
  | Rain    | Wet Grass   |

* Data: the entries from which to learn the CPTs

  | Cloudy | Sprikler | Rain | Wet Grass |
  | ------ | -------- | ---- | --------- |
  | Yes    | No       | Yes  | Yes       | 
  | No     | No       | No   | No        | 
  | No     | Yes      | No   | Yes       | 
  
**IMPORTANT: the names of the Edges entries and the names of the Data columns must coincide.**

You can also play with a pre-trained example by clicking the `Load Example` button

### Querying the Network

Click on the nodes to see their prior distributions. Here you can also set the evidence for the target node.
When you're done with the evidence setting, select the node you want to query and use the sidebar panel to perform the query and see how the distribution changes.

## Development, Testing and Deployment

(WIP) These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. 

## Built With

* [R](https://www.r-project.org/) - Main Language
* [SHINY](https://shiny.rstudio.com/) - Used to build the interactive web app straight from R
* [BNLEARN](https://www.bnlearn.com/) - Main depencency of the project, used to learn and query the bayesian network
* [VISNETWORK](https://datastorm-open.github.io/visNetwork/) - For network visualization
* [SHINYAPPS.IO](http://shinyapps.io/) - RStudio servers where the webapp is hosted

## Authors

* **Tommaso Buonocore** - *Author and Repository Maintainer* - \([GitHub](https://github.com/detsutut)\) \([LinkedIn](https://www.linkedin.com/in/tbuonocore/)\)

## License

This project is licensed under the GPLv3 License - see the [LICENSE.md](LICENSE.md) file for details

