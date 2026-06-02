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

dir.create("terra_tmp", showWarnings = FALSE)

# ============================================================
# INPUTS
# ============================================================

target_raster_path <- "input/data/HabitatMap_it1.tif"
output_raster <- "input/data/HabitatMap_it2.tif"

# ============================================================
# LOAD DATA
# ============================================================

cat("Loading target raster...\n")
target_raster <- rast(target_raster_path)
cat("Loaded target raster.\n")

cat("Loading the closed forest raster mask...\n")
burn_raster <- rast("input/data/forest_data/forest_mask_it2.tif")
cat("Loaded closed forest burn raster.\n")

# ============================================================
# OVERWRITE TARGET RASTER
# ============================================================

cat("Preparing forest mask (keeping only value 6)...\n")

# IMPORTANT FIX: remove non-forest (0) so it does NOT overwrite habitat map
burn_raster[burn_raster != 6] <- NA

cat("Applying forest overwrite...\n")

updated_raster <- cover(
  burn_raster,
  target_raster,
  filename = output_raster,
  overwrite = TRUE,
  wopt = list(
    datatype = "INT2U",
    gdal = c(
      "COMPRESS=DEFLATE",
      "PREDICTOR=2",
      "BIGTIFF=YES"
    )
  )
)

cat("Forest remasking done: HabitatMap_it2.tif mask.\n")


# ----------------------------
# CLIP TO MAPTILES
# ----------------------------

raster_path <- "input/data/HabitatMap_it2.tif"

polygon_path <- "input/data/mapsheet_grid.gpkg"

output_dir <- "input/data/habitat_map_maptiles/maptiles_it2"

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

cat("Done clipping HabitatMap_it2.tif to maptiles extents.\n")


# ----------------------------
# CLIP MASK TO TILES
# ----------------------------

new_mask_path <- file.path("input", "data", "habitat_map_maptiles", "maptiles_it2")
existing_tiles_path <- file.path("input", "model_data", "tiles")

split_dirs <- c("training", "validation", "test")

output_base <- file.path("input", "model_data", "masks_it2")
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
        paste0("mask_it2_", row, "_", col, "_", mapnr, "_", region, ".tif")
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
cat("Done clipping masks to tiles for iteration 2.\n")
cat("=====================================\n")