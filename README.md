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
        │   ├── forest_data/
        │   │   ├── forest_mask_it1.gpkg
        │   │   ├── forest_mask_it1.tif
        │   │   └── ...
        │   │
        │   ├── habitat_map_maptiles/
        │   │   ├── maptiles_it1/
        │   │   │   ├── habitat_map_tile_1011.tif
        │   │   │   └── ...
        │   │   ├── maptiles_it2/
        │   │   │   └── ...
        │   │   └── maptiles_it3/
        │   │       └── ...
        │   │
        │   ├── HabitatMap_it1.tif
        │   ├── HabitatMap_it2.tif
        │   └── HabitatMap_it3.tif
        │
        └── model_data/
            ├── masks_it1/
            │   ├── test/
            │   │   ├── mask_it1_15_374_1031_22.tif
            │   │   └── ...
            │   ├── training/
            │   │   └── ...
            │   └── validation/
            │       └── ...
            │
            ├── masks_it2/
            │   ├── test/
            │   │   ├── mask_it2_15_374_1031_22.tif
            │   │   └── ...
            │   ├── training/
            │   │   └── ...
            │   └── validation/
            │       └── ...
            │
            ├── masks_it3/
            │   ├── test/
            │   │   ├── mask_it3_15_374_1031_22.tif
            │   │   └── ...
            │   ├── training/
            │   │   └── ...
            │   └── validation/
            │       └── ...
            │
            └── tiles/
                ├── test/
                │   ├── test_15_374_1031_22.tif
                │   └── ...
                ├── training/
                │   └── ...
                └── validation/
                    └── ...
```

