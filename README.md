# shinyDBNet

shinyDBNet is a Shiny application that provides an interactive framework for reasoning with Discrete Bayesian Networks.

## Getting Started

You can run the app from [here](https://detsutut.shinyapps.io/shinyDBNet/) or from your local machine. Follow the instruction in [Development, Testing and Deployment](https://github.com/detsutut/shinyDBNet#development-testing-and-deployment) for the latter approach.

### Loading the network

In order to load the network, three files must be uploaded. These files describes the network in terms of its nodes, its edges and the data from which to learn the CPTs.
Files have to be in \*.csv format and must follow this templates:
* Nodes

  | id  | label     |
  | ----| --------- |
  |  1  | Cloudy    |
  |  2  | Sprikler  |
  |  3  | Rain      |
  |  4  | Wet Grass |

* Edges

  | from | to  |
  | ---- | --- |
  | 1    | 2   |
  | 1    | 3   |
  | 2    | 4   |
  | 3    | 4   |

* Data

  | Cloudy | Sprikler | Rain | Wet Grass |
  | ------ | -------- | ---- | --------- |
  | Yes    | No       | Yes  | Yes       | 
  | No     | No       | No   | No        | 
  | No     | Yes      | No   | Yes       | 

### Querying the Network

## Development, Testing and Deployment

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. 

## Built With

* [R](https://www.r-project.org/) - Main Language
* [SHINY](https://shiny.rstudio.com/) - Used to build the interactive web app straight from R
* [BNLEARN](https://www.bnlearn.com/) - Main depencency of the project, used to learn and query the bayesian network
* [SHINYAPPS.IO](http://shinyapps.io/) - RStudio servers where the webapp is hosted

## Authors

* **Tommaso Buonocore** - *Initial work* - [Detsutut](https://github.com/detsutut)

## License

This project is licensed under the GPLv3 License - see the [LICENSE.md](LICENSE.md) file for details

