library(fs)
library(amerifluxr)
library(dplyr)
library(tidyr)
library(sf)
library(readr)
get_site_locs <- function(neon_kmz, neon_field_path) {
  
  # Ameriflux ---------------------------------------------------------------
  amf <- amf_site_info() |> 
    dplyr::filter(COUNTRY == "USA", !STATE %in% c("AK", "HI")) |> 
    select(site_id = SITE_ID, site_name = SITE_NAME, lon = LOCATION_LONG, lat = LOCATION_LAT)

  # NEON --------------------------------------------------------------------
  neon_kml <-
    path("/vsizip", neon_kmz, "doc", ext = "kml")
  neon_field <- st_read(neon_field_path)
  neon_core <- neon_field |> 
    filter(siteType == "Core Terrestrial")
  site_ids <- neon_core |> as_tibble() |> select(siteName, siteID)
  
  neon_towers <-
    st_read(neon_kml, layer = "NEON Core Terrestrial") |> 
    select(-Description) |> 
    separate(Name, into = c("Domain", "Name"), sep = " - ") |> 
    #need to use fuzzy join because site names differ slightly
    fuzzyjoin::stringdist_left_join(site_ids, by = c(Name = "siteName")) |> 
    # fix manually: Guanica Forest, Yellowstone Northern Range (Frog Rock), Toolik Lake
    mutate(siteID = case_when(
      Name == "Guanica Forest" ~ "GUAN",
      Name == "Yellowstone Northern Range (Frog Rock)" ~ "YELL",
      Name == "Toolik Lake" ~ "TOOL",
      .default = siteID 
    )) |> 
     st_as_sf() |> 
    filter(!Domain %in% c(18:20, 4)) |> #exclude alaska and hawaii and carribean
    select(site_name = Name, site_id = siteID)
  
  neon_towers <- 
    neon_towers |>
    mutate(lon = st_coordinates(neon_towers)[, "X"], lat = st_coordinates(neon_towers)[, "Y"]) |>
    as_tibble() |>
    select(-geometry)
  
  bind_rows(NEON = neon_towers, Ameriflux = amf, .id = "dataset") |> 
    mutate(crs = "WGS 84") #I think this is correct

}

df <- 
  get_site_locs(neon_kmz = "data/NEON_Field_Sites_KMZ_v18_Mar2023.kmz", neon_field_path = "data/Field_Sampling_Boundaries_2020/")

#create some made-up radii for buffers around each point (in meters?)
set.seed(123)
df |> 
  mutate(buffer_radius_m = sample(c(300, 500, 1000), size = n(), replace = TRUE)) |> 
  write_csv("fluxtower_locations.csv")
