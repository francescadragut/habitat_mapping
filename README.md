# Setup

## Directory structure
```
.
└── habitat_mapping/
    ├── environments
    ├── figures
    ├── input
    ├── iterations
    ├── logs
    ├── output
    ├── .gitignore
    ├── Data annex.md
    └── README.md
```

## Set up environments
The models were trained on a Linux-based HPC cluster. Download the Miniforge3 installer from https://conda-forge.org/download/, add it in ```habitat_mapping/environments```
```
.
└── habitat_mapping/
    └── environments/
        ├── python/
        │   ├── create_env.sh
        │   ├── environment.yml
        │   ├── install_torch.sh
        │   └── setup_env.sh
        ├── r/
        │   ├── geo_env_r.yml
        │   └── e_env.sh
        └── Miniforge3-Linux-x86_64.sh
```
        
Install Miniforge3 on the HPC using the following command:\
```bash environments/python/Miniforge3-Linux-x86_64.sh -b -p $HOME/miniforge3```

Create Python environment using:\
```sbatch environments/python/create_environment.sh```\
```sbatch environments/python/install_torch.sh```

Create R environment using:\
```sbatch environments/r/r_env.sh```

All other scripts activate the correct environments at runtime. 

## Project data download
Download data from https://huggingface.co/datasets/francescadragut/habitat_mapping. The dataset includes a zip archive of the input and output data. Unzip the folders and add them to the root directory. The project input folder structure is:

```
.
└── habitat_mapping/
    └── input/
        ├── data/
        │   └── grid_selection_partition.gpkg       
        └── model_data/
            ├── masks_it1/
            │   ├── test/
            │   │   ├── mask_it1_15_374_1031_22.tif
            │   │   └── ...
            │   ├── training/
            │   │   └── ...
            │   └── validation/
            │       └── ...
            ├── masks_it2/
            │   ├── test/
            │   │   ├── mask_it2_15_374_1031_22.tif
            │   │   └── ...
            │   ├── training/
            │   │   └── ...
            │   └── validation/
            │       └── ...
            ├── masks_it3/
            │   ├── test/
            │   │   ├── mask_it3_15_374_1031_22.tif
            │   │   └── ...
            │   ├── training/
            │   │   └── ...
            │   └── validation/
            │       └── ...
            └── tiles/
                ├── test/
                │   ├── test_15_374_1031_22.tif
                │   └── ...
                ├── training/
                │   └── ...
                └── validation/
                    └── ...
```

## Tile selection
The model data was selected using random selection on a polygon grid. The grid was generated in QGIS using the extent of the Habitat Map of Switzerland raster, each grid tile of 512x512m. Eligible tiles were selected by comparing to the features from the 512x512m grid to the orthophoto maptile grid. The selection was done using ```Vector selection``` in QGIS and the ```are within``` function. This ensured that only tiles covering 100% of a certain maptile are considered. This eliminated tiles which were on the border of Switzerland or on the border of multiple maptiles, to avoid large NA areas or subsequent merging of tiles spanning on multiple orthophoto maptiles.

Since the rasters have 1m spatial resolution, the size fits the 512x512px size required by U-Net. In R, the grid was intersected with the biogeographical regions of Switzerland. 

## Data preparation
Data preparation consists of:
- **Iteration 1**:
  - Clip Habitat Map of Switzerland raster to the orthophoto maptile footprint
  - Clip all selected grid tiles within each orthophoto maptile and save them in the training, validation or test partition based on the split they belong to
  - Clip masks on the extent of the tiles for each orthophoto maptile - clipped them on the tile extents and not on the polygon extents to ensure perfect match between tile-mask pixels
- **Iteration 2**:
  - Re-mask the Habitat Map of Switzerland using the NFI forest mask raster including both closed and open forests
  - Clip the re-masked Habitat Map to the orthophoto maptile footprint
  - Clip masks using the extent of the tiles obtained in the first iteration
- **Iteration 3**:
  - Re-mask the Habitat Map of Switzerland using the NFI forest mask raster including only closed forests
  - Clip the re-masked Habitat Map to the orthophoto maptile footprint
  - Clip masks using the extent of the tiles obtained in the first iteration
