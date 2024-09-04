write_agb <- function(agb, outdir = "output") {
  dir_create(outdir)
  filename <- paste0(unique(agb$product), "_agb.csv")
  outpath <- fs::path(outdir, filename)
  agb |> 
    select(product, year, SITE_ID, ffp_radius, agb_Mg_ha) |> 
    readr::write_csv(outpath)
  #return
  outpath
}