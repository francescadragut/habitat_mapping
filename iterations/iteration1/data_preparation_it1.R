# ============================================================
# Burn forest polygons into habitat raster as value 6
# HPC-safe version
# ============================================================
library(terra)
library(sf)

terraOptions(
  memfrac = 0.8,
  tempdir = "terra_tmp",
  progress = 1
)

# ----------------------------
# CLIP TO MAPTILES
# ----------------------------

raster_path <- "input/data/HabitatMap_it1.tif"

polygon_path <- "input/data/mapsheet_grid.gpkg"

output_dir <- "input/data/habitat_map_maptiles/maptiles_it1"

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# ----------------------------
# LOAD DATA
# ----------------------------

cat("Loading polygons...\n")

polygons <- st_read(
  polygon_path,
  quiet = TRUE
)

# convert ONCE to terra vector
polygons <- vect(polygons)

cat("Opening raster...\n")

# IMPORTANT:
# open lazily from disk
raster_data <- rast(raster_path)

cat("Starting clipping...\n")

# ----------------------------
# LOOP
# ----------------------------

for (i in 1:nrow(polygons)) {

  mapnr <- polygons$mapnr[i]

  cat("Processing:", mapnr, "\n")

  # single polygon only
  geom <- polygons[i]

  # crop first (cheap)
  r_crop <- crop(raster_data, geom)

  # mask second (expensive)
  r_mask <- mask(r_crop, geom)

  output_path <- file.path(
    output_dir,
    paste0("habitat_map_tile_", mapnr, ".tif")
  )

  writeRaster(
    r_mask,
    output_path,
    overwrite = TRUE,
    wopt = list(
      gdal = c(
        "COMPRESS=DEFLATE",
        "PREDICTOR=2",
        "BIGTIFF=YES"
      )
    )
  )

  cat("Saved:", output_path, "\n")

  # VERY IMPORTANT
  rm(r_crop, r_mask)
  gc()
}

cat("Done clipping HabitatMap_it1.tif to maptiles extents.\n")


# ----------------------------
# CREATE IMAGE TILES (IT1)
# ----------------------------

polygons <- vect("input/data/grid_selection_partition.gpkg")
selected_polygons <- polygons[polygons$selected == 1, ]

mapsheets_path <- "input/data/habitat_map_maptiles/maptiles_it1"

split_map <- c(
  "1" = "training",
  "2" = "validation",
  "3" = "test"
)

tile_output_base <- file.path("input", "model_data", "tiles")

for (split in split_map) {
  dir.create(
    file.path(tile_output_base, split),
    recursive = TRUE,
    showWarnings = FALSE
  )
}

mapsheets <- list.files(
  mapsheets_path,
  pattern = "\\.tif$",
  full.names = FALSE
)

cat("\n=====================================\n")
cat("Creating image tiles (IT1)\n")
cat("=====================================\n\n")

for (file in mapsheets) {
  
  mapnr <- as.numeric(
    sub(".*_([0-9]+)\\.tif$", "\\1", basename(file))
  )
  
  if (is.na(mapnr)) next
  
  relevant_polygons <- selected_polygons[
    selected_polygons$mapnr.x == mapnr,
  ]
  
  if (nrow(relevant_polygons) == 0) next
  
  image_raster <- rast(
    file.path(mapsheets_path, file)
  )
  
  res_xy <- res(image_raster)
  
  tile_w <- 512 * res_xy[1]
  tile_h <- 512 * res_xy[2]
  
  cat("Map:", mapnr,
      "- polygons:", nrow(relevant_polygons), "\n")
  
  for (i in 1:nrow(relevant_polygons)) {
    
    poly <- relevant_polygons[i, ]
    
    split_name <- split_map[
      as.character(poly$split)
    ]
    
    if (is.na(split_name)) next
    
    cxy <- crds(centroids(poly))
    
    cx <- cxy[1, 1]
    cy <- cxy[1, 2]
    
    tile_ext <- ext(
      cx - tile_w / 2,
      cx + tile_w / 2,
      cy - tile_h / 2,
      cy + tile_h / 2
    )
    
    tile <- crop(
      image_raster,
      tile_ext
    )
    
    out_file <- file.path(
      tile_output_base,
      split_name,
      paste0(
        "tile_",
        poly$row_index.x, "_",
        poly$col_index.x, "_",
        mapnr, "_",
        poly$Unterregio,
        ".tif"
      )
    )
    
    writeRaster(
      tile,
      out_file,
      overwrite = TRUE,
      wopt = list(
        gdal = c(
          "COMPRESS=DEFLATE",
          "PREDICTOR=2",
          "BIGTIFF=YES"
        )
      )
    )
    
    rm(tile)
    gc()
  }
  
  rm(image_raster)
  gc()
}

cat("\nFinished creating image tiles.\n")

# ----------------------------
# CLIP MASK TO TILES
# ----------------------------

new_mask_path <- file.path("input", "data", "habitat_map_maptiles", "maptiles_it1")
existing_tiles_path <- file.path("input", "model_data", "tiles")

split_dirs <- c("training", "validation", "test")

output_base <- file.path("input", "model_data", "masks_it1")
dir.create(output_base, recursive = TRUE, showWarnings = FALSE)

for (s in split_dirs) {
  dir.create(file.path(output_base, s), recursive = TRUE, showWarnings = FALSE)
}

# ----------------------------
# FILE LIST
# ----------------------------

new_mask_files <- list.files(
  new_mask_path,
  pattern = "\\.tif$",
  full.names = TRUE
)

cat("\n=====================================\n")
cat("Found", length(new_mask_files), "new mask rasters\n")
cat("=====================================\n\n")

# ----------------------------
# MAIN LOOP
# ----------------------------

for (new_mask_file in new_mask_files) {
  
  cat("\n-------------------------------------\n")
  cat("File:", basename(new_mask_file), "\n")
  
  mapnr <- as.numeric(gsub(".*_([0-9]+)\\.tif$", "\\1", basename(new_mask_file)))
  
  if (is.na(mapnr)) {
    cat("SKIP: cannot extract mapnr\n")
    next
  }
  
  cat("Mapnr:", mapnr, "\n")
  
  new_mask <- rast(new_mask_file)
  
  # ----------------------------
  # LOOP SPLITS
  # ----------------------------
  
  for (split_dir in split_dirs) {
    
    tile_dir <- file.path(existing_tiles_path, split_dir)
    
    if (!dir.exists(tile_dir)) {
      cat("Missing directory:", tile_dir, "\n")
      next
    }
    
    existing_tile_files <- list.files(
      tile_dir,
      pattern = paste0(".*_", mapnr, "_.*\\.tif$"),
      full.names = TRUE
    )
    
    if (length(existing_tile_files) == 0) {
      cat("No tiles found for map", mapnr, "in", split_dir, "\n")
      next
    }
    
    cat("Split:", split_dir, "- tiles found:", length(existing_tile_files), "\n")
    
    # ----------------------------
    # PROCESS TILES
    # ----------------------------
    
    for (tile in existing_tile_files) {
      
      cat("  Tile:", basename(tile), "\n")
      
      ref <- rast(tile)
      
      # IMPORTANT: resample + crop in correct order
      mask_aligned <- crop(
        resample(new_mask, ref, method = "near"),
        ref
      )
      
      # ----------------------------
      # filename parsing (safe)
      # ----------------------------
      
      parts <- strsplit(basename(tile), "_")[[1]]
      
      if (length(parts) < 5) {
        cat("  SKIP: unexpected filename format\n")
        next
      }
      
      row <- parts[2]
      col <- parts[3]
      region <- sub("\\.tif$", "", parts[5])
      
      # ----------------------------
      # OUTPUT
      # ----------------------------
      
      out_dir <- file.path(output_base, split_dir)
      dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
      
      out_file <- file.path(
        out_dir,
        paste0("mask_it1_", row, "_", col, "_", mapnr, "_", region, ".tif")
      )
      
      writeRaster(
        mask_aligned,
        out_file,
        overwrite = TRUE,
        wopt = list(
          datatype = "INT2U",
          gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "BIGTIFF=YES")
        )
      )
      
      if (file.exists(out_file)) {
        cat("  WROTE:", out_file, "\n")
      } else {
        cat("  FAILED WRITE:", out_file, "\n")
      }
      
      rm(ref, mask_aligned)
      gc()
    }
  }
  
  rm(new_mask)
  gc()
}

cat("\n=====================================\n")
cat("Done clipping masks to tiles for iteration 1.\n")
cat("=====================================\n")