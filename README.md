
# Fluxtower Above-ground Biomass Intercomparison

<!-- badges: start -->
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
<!-- badges: end -->

The goal of fluxtower-sites is to estimate total above ground biomass for the "footprints" of flux towers from a variety or raster data products.  This is a collaboration between [CCT Data Science](https://datascience.cct.arizona.edu/) and the [Moore lab](https://snre.arizona.edu/david-moore) at University of Arizona.

## Files

- `data/` contains raw data and metadata
- `R/` contains R scripts with functions to be `source()`ed
- `notes/` contains R scripts with work-in-progress workflows

## Reproducibility

> [!NOTE] 
> External data is required for this code to be reproducible.  See [EcosystemEcologyLab/AGB-products](https://github.com/EcosystemEcologyLab/AGB-products) for code and metadata on how this external data was created.

There are two options for running the workflow.  I recommend the "targets" version, but the "manual" version may be easier to edit and understand.

### Manual

Run `extract_agb_fluxtowers.R`.  This extracts data for all the data products and combines the results into a single .csv file.  This workflow is *very* slow because of some high resolution data products.  There is an option to un-comment some code to run the extraction function on a single product at a time.

### Targets

Simply run `targets::tar_make(as_job = TRUE)` to kick off the pipeline.  `as_job = TRUE` runs this as a background process so your R console is still free.  You can monitor the progress of the pipeline by running `targets::tar_visnetwork()` periodically or by using `tar_watch()` to launch a Shiny app. When the pipeline completes, a .csv file for each data product will be saved to `output/`.  You can read them all in as a single data frame with:

```r
library(readr)
agb <- read_csv(list.files("output", full.names = TRUE))
```

This is also quite slow for some of the products (first run of the pipeline took over a day with 2 workers and 25GB of RAM).  Depending on your computer's specifications you may improve performance by increasing the number of workers used by editing the `crew_controller_local()` function arguments in `_targets.R`.  You might also speed things up by increasing the value for the `max_cells_in_memory` in the `extract_mean_agb()` function call in `_targets.R`---this allows more pixels to be loaded into memory.  Keep in mind that this value is *per worker*, so if you have many parallel workers you probably need to *decrease* `max_cells_in_memory`.  Also note that any edits to functions in the pipeline will invalidate all downstream targets and cause them to be re-run when you next run `tar_make()`.


------------------------------------------------------------------------
Developed in collaboration with the University of Arizona [CCT Data Science](https://datascience.cct.arizona.edu/) team