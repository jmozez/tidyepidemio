# Sudden infant death syndrome (SIDS) in the 100 counties of North Carolina,
# 1974-78 and 1979-84, with live births and county centroids in projected
# UTM (zone 17) kilometres.
# Source: spData::nc.sids (CC0), from Cressie N, Chan NH (1989). Spatial
# modeling of regional variables. J Am Stat Assoc 84:393-401, and
# Symons MJ, Grimson RC, Yuan YC (1983). Biometrics 39:193-205.
data("nc.sids", package = "spData")
d <- spData::nc.sids
nc_sids <- tibble::tibble(
  county = rownames(d),
  x_km = d$x, y_km = d$y, lon = d$lon, lat = d$lat,
  births_1974 = as.integer(d$BIR74), sids_1974 = as.integer(d$SID74),
  births_1979 = as.integer(d$BIR79), sids_1979 = as.integer(d$SID79),
  nonwhite_births_1974 = as.integer(d$NWBIR74)
)
usethis::use_data(nc_sids, overwrite = TRUE)
