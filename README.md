# Data annex
## Study area
The study area covers Switzerland, with sample selection for model training (Figure 1). The footprint of the available aerial orthophotos for Switzerland was gridded into 512x512px polygons. The available aerial orthophotos are tiled into multiple tiles of ~210km2. The tiles placed on multiple tiles were removed, to avoid subsequent merging of tile parts.

The sampling strategy was random but stratified on the biogeographical regions of Switzerland (Biogeographische Regionen Der Schweiz (CH), 2020). For each biogeographical region, 5% of the tiles within the region were chosen. The tiles were randomly assigned per biogeographical region into 70% training, 20% validation and 10% test.  

<div align="center">

  <img src="https://github.com/user-attachments/assets/9ad707c7-0b4f-4d1e-a651-42eb7a45fcce" alt="Habitat Mapping Example" width="400" />

  *Figure 1: Example of habitat mapping output from our model.*

</div>

## Data
### Orthophotots
**Source**: https://www.swisstopo.admin.ch/en/orthoimage-swissimage-10, resampled to 1m spatial resolution by WSL
**Year**: 2024
**Preprocessing for this study**: 
The data used in this study consists of 1m resolution Swiss aerial orthomaps from 2024. The original orthomaps are 16-bit 4-band images (RGB-NIR). For each area, the corresponding image was converted to grayscale using Equation 1. Then the values were scaled to 8-bit values using the 98th percentile, to normalize the histogram and remove extreme values.

<div align="center">

  $$
    \rho_{\mathrm{BW}} = \frac{\rho_{\mathrm{RED}} + \rho_{\mathrm{GREEN}} + \rho_{\mathrm{BLUE}}}{3}
  $$

  *Equation 1: Formula for RGB to grayscale conversion.*

</div>

### Habitat Map of Switzerland
**Source**: https://www.envidat.ch/#/metadata/the-habitat-map-of-switzerland-v1-1 rasterized on class level by WSL
**DOI**: 10.16904/envidat.515
**Year**: 2022
