# Influenza A (H1N1) outbreak in a boys' boarding school, northern England,
# January 1978: number of the 763 pupils confined to bed on each day.
# Source: Anonymous (1978). Influenza in a boarding school. BMJ 1(6112):587.
# Published counts (facts) transcribed from the report.
flu_boarding_school_1978 <- tibble::tibble(
  date = as.Date("1978-01-22") + 0:13,
  in_bed = c(3L, 8L, 26L, 76L, 225L, 298L, 258L, 233L, 189L, 128L, 68L, 29L, 14L, 4L),
  population = 763L
)
usethis::use_data(flu_boarding_school_1978, overwrite = TRUE)
