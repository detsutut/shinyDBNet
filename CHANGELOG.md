# Changelog

All notable changes to this project will be documented in this file.

## [unreleased] - 2020-02-12

### Added

- Nothing relevant has been added

### Changed

- Nothing relevant has been changed

### Removed

- Nothing relevant has been removed

## [1.0.2] - 2020-02-12

### Added

- Arcs suggestion: when the BN is created from the data, the app may suggest some additional connections that were absent in the user-defined dag but have emerged from data-driven structure learning. The square brackets shows the strength of the proposed arcs, i.e. proportion of times an arc have been discovered among the bootstrapped structures.

- Changelog

### Changed

- Bug fix: a mismatch of variable names was causing troubles with the edges (i.e. arcs) of the network.

- UI changes:
  * ADFICE-IT Logo

### Removed

- Nothing relevant has been removed

## [1.0.1] - 2020-02-07

### Added

- CPT View: a button in the side menu allows to inspect the values of Conditional Probability Tables of each node. CPTs are read only and can't be edited.

- Basicpipeline: a R script that relies only upon the bnlearn package showing the standard pipeline to learn and query a discrete Bayesian network. No shiny (thus no graphics) involved.

- UI Improvement:
  * Credits to ZonMv and UMC
  * Upload/Download/Screen/Info top-right floating panel
  
- Readme

- Toy datasets in data folder

- Pretrained car insurance network as example

- Try-catch network to avoid dumb crashes

- AGPLv3.0 license

### Changed

- File loading: only edges + data, nodes file not necessary

- UI changes:
  * Logo
  * Button colors
  * Size of the popup panels
  
- Project's folders structure

- Some functions have been moved from server.R to utilities.R for consistency

### Removed

- Nothing relevant has been removed

## [<1.0.1] - 2020-01-09

### Added

- Bayesian Network app backbone imported from a private repository

### Changed

- Nothing relevant has been changed

### Removed

- Nothing relevant has been removed

[unreleased]: https://github.com/detsutut/shinyDBNet
[1.0.2]: https://github.com/detsutut/shinyDBNet/tree/116b42e216dae4edb1d147585ad6312147faa714
[1.0.1]: https://github.com/detsutut/shinyDBNet/tree/9293872ef2285178edfe53c09ba3fc690025cd7d
[<1.0.1]: https://github.com/detsutut/shinyDBNet/tree/54c273013350dd8886c69e9a6a1e671343880a66
