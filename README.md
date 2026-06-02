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
**Source**: https://www.swisstopo.admin.ch/en/orthoimage-swissimage-10, resampled to 1m spatial resolution by WSL\
**Year**: 2024\
**Preprocessing for this study**: \
The data used in this study consists of 1m resolution Swiss aerial orthomaps from 2024. The original orthomaps are 16-bit 4-band images (RGB-NIR). For each area, the corresponding image was converted to grayscale using Equation 1. Then the values were scaled to 8-bit values using the 98th percentile, to normalize the histogram and remove extreme values.

<div align="center">

  $$
    \rho_{\mathrm{BW}} = \frac{\rho_{\mathrm{RED}} + \rho_{\mathrm{GREEN}} + \rho_{\mathrm{BLUE}}}{3}
  $$

  *Equation 1: Formula for RGB to grayscale conversion.*

</div>

### Habitat Map of Switzerland
**Source**: https://www.envidat.ch/#/metadata/the-habitat-map-of-switzerland-v1-1 rasterized on class level by WSL\
**DOI**: 10.16904/envidat.515\
**Year**: 2022\

### National Forest Inventory (NFI)
The National Forest Inventory is a project of the WSL in collaboration with the Federal Office for the Environment (FOEN). The forest inventory is based on nation-wide LiDAR scans. The forest types are classified using the following rules:\
- 1 = closed_forest (> 60% average Deckungsgrad)
- 2 = open forest (< 60 % & > 20 % average Deckungsgrad)
- 3 = shrub forest (separate WSL-obtained Sentinel 2 model, overrules all other forest types)

## Results
| IoU | Iteration 1 | Iteration 2 | Iteration 3 |
| --- | --- | --- | --- |
| **Mean** | 0.2964 | 0.2907 | 0.3136 |
| **Class 1** | 0.0508 | 0.1017 | 0.2289 |
| **Class 2** | 0.0000 | 0.0000 | 0.0000 |
| **Class 3** | 0.5734 | 0.3972 | 0.4106 |
| **Class 4** | 0.5445 | 0.5190 | 0.5206 |
| **Class 5** | 0.0010 | 0.0000 | 0.0019 |
| **Class 6** | 0.8007 | 0.8272 | 0.8227 |
| **Class 7** | 0.0000 | 0.0000 | 0.0000 |
| **Class 8** | 0.3992 | 0.4510 | 0.4987 |
| **Class 9** | 0.2978 | 0.3198 | 0.3393 |

### Iteration 1
- **Confusion matrix**:


|  | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 275343 | 2331492 | 2085389 | 108 | 622691 | 0 | 46260 | 19627 |  |
| 2 | 0 | 44889 | 3412991 | 68 | 453875 | 0 | 13431 | 9011 |  |
| 3 | 1638 | 2240341 | 5337185 | 3143 | 429150 | 0 | 30966 | 100876 |  |
| 4 | 18669 | 0 | 6042609 | 51772154 | 12170 | 2956969 | 0 | 1415326 | 854187 |
| 5 | 14416 | 0 | 587938 | 2890725 | 5469 | 737910 | 0 | 16893 | 10681 |
| 6 | 0 | 0 | 158509 | 4204280 | 35796 | 53571593 | 0 | 10022 | 129600 |
| 7 | 0 | 0 | 61817 | 14955105 | 0 | 133953 | 0 | 30192 | 34482 |
| 8 | 202 | 0 | 36266 | 9255145 | 1 | 183501 | 0 | 7596880 | 256998 |
| 9 | 226 | 0 | 93022 | 2823269 | 0 | 1 | 838601 | 0 | 152994 |
