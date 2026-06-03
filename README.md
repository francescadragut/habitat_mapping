# Data annex
## Study area
The study area covers Switzerland, with sample selection for model training (Figure 1). The footprint of the available aerial orthophotos for Switzerland was gridded into 512x512px polygons. The available aerial orthophotos are tiled into multiple tiles of ~210km2. The tiles placed on multiple tiles were removed, to avoid subsequent merging of tile parts.

The sampling strategy was random but stratified on the biogeographical regions of Switzerland (Biogeographische Regionen Der Schweiz (CH), 2020). For each biogeographical region, 5% of the tiles within the region were chosen. The tiles were randomly assigned per biogeographical region into 70% training, 20% validation and 10% test.  

<div align="center">

  <img src="https://github.com/user-attachments/assets/9ad707c7-0b4f-4d1e-a651-42eb7a45fcce" alt="Habitat Mapping Example" width="800" />

  *Figure 1: Example of habitat mapping output from our model.*

</div>

## Data
### Orthophotots
**Source**: https://www.swisstopo.admin.ch/en/orthoimage-swissimage-10, resampled to 1m spatial resolution by WSL\
**Year**: 2024\
**Preprocessing for this study**:\
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
**Year**: 2022

### National Forest Inventory (NFI)
The National Forest Inventory is a project of the WSL in collaboration with the Federal Office for the Environment (FOEN). The forest inventory is based on nation-wide LiDAR scans. The forest types are classified using the following rules:
- 1 = closed_forest (> 60% average Deckungsgrad)
- 2 = open forest (< 60 % & > 20 % average Deckungsgrad)
- 3 = shrub forest (separate WSL-obtained Sentinel 2 model, overrules all other forest types)

## Model architecture


## Results
| IoU | Iteration 1 | Iteration 2 | Iteration 3 |
| --- | --- | --- | --- |
| **Mean** | **0.2964** | **0.2907** | **0.3136** |
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
- **Confusion matrix visualization**:
  - Most water classified as rock
  - Most wetlands classified as grasslands
  - Confusion between rock and grasslands
  - Shrubs classified as grasslands and forests
  - Highest accuracy in forest classification, confusion with grasslands and rock
  - No pioneer vegetation detected, mostly classified as grasslands
  - High amount of cropland classified as grasslands, but not the other way around
  - Built habitats classified as grasslands
<img width="1000" alt="confusion_matrix_it1" src="https://github.com/user-attachments/assets/0c88f645-226d-419f-ade0-4a1b7c4d7289" />

### Iteration 2
- **Confusion matrix visualization**:
  - Most water and wetlands still classified as grassland
  - Less grassland misclassified as rock, but more rock misclassified as grassland
  - Most shrubbery misclassified as grassland
  - More forest misclassified as grassland compared to iteration 1
  - Cropland still misclassified as grassland
  - Built habitats still misclassified as grassland
<img width="1000" alt="confusion_matrix_it2" src="https://github.com/user-attachments/assets/1dfd80f7-828b-4214-8d22-9473d95a181a" />
  

### Iteration 3
- **Confusion matrix visualization**:
  - Increased accuracy for water and built habitats classification i.e. the dense forest remasking improved classification
  - Same patterns for wetlands, pioneer vegetation and shrubbery as in iteration 1 and 2
  - Same pattern for rock misclassified as grassland compared to iteration 2
  - Increased misclassification of grassland as cropland, but decreased misclassification of cropland as grassland
<img width="1000" alt="confusion_matrix_it3" src="https://github.com/user-attachments/assets/e2833e0a-167f-4076-821a-e77c8b1e8a1c" />

## Model performance
Similar training-validation loss curve pattern for all three iterations (example in Figure 2). The training curve is stable, while the validation curve is unstable and has peaks especially in epochs 2, 8, 13, 23, 25, 26, 29 and 30. The model used for inference was the one with the lowest validation loss to ensure a generalizable model which is not overfitted on the training data.

| Iteration | Epoch | Lowest validation Loss |
| --- | --- | --- |
| 1 | 27 | 0.8429 |
| 2 | 28 | 0.7782 |
| 3 | 28 | 0.7704 |

<div align="center">

  <img width="1498" height="661" alt="training_validation_loss_it3" src="https://github.com/user-attachments/assets/945d2811-f9aa-4e2b-b23b-334158e67a89" />

  *Figure 2: Training-validation loss curve for iteration 3.*

</div>

## Future improvement
- **Elevation gradient additional sampling**: the high misclassification of rock as grassland suggests that there are not enough representative samples of rock in the alpine areas. There are many types of grasslands and alpine ones differ from the plateau grasslands which are more managed and sturcturally similar to croplands.
- **Water class handling**: water will be either masked out from the model using automatic digitization from old topographic maps (e.g. Siegfried maps or Old National Maps). Water bodies haven't changed too much in the past 100 years, and if they changed, that is accurately captured in the topographic maps, compared to e.g. wetlands, which are more prone to interpretation issues or differing map scales.
- **Wetland handling**: more variants will be considered:
  - Merging them into the grasslands and reclassifying grasslands using other ML models to integrate variables such as topographic wetness index (TWI), or climatic variables, or distance to water bodies
  - Using training data obtained digitized topographic maps to train a binary _wetland/non-wetland_ model - issue: differing accuracy across Switzerland, 
