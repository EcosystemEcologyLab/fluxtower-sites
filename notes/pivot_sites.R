# Combine and pivot wider data extracted from each data product
pivot_sites <- function(..., site_locs, out_path = "docs/site_data.csv") {
  sites_long <- bind_rows(...)
  site_locs <- 
    site_locs |>
    st_zm() |> 
    as_tibble() |>
    mutate(X = st_coordinates(geometry)[,"X"], Y = st_coordinates(geometry)[,"Y"]) |>
    select(-geometry)
  sites_wide <- pivot_wider(sites_long, names_from = product, values_from = agb)
  out <- bind_cols(site_locs, sites_wide) |> select(-site_rowid)
  readr::write_csv(out, out_path)
  #return
  out_path
}