#' Read the raw data file from Mimetas, tidy it and save it as an .rda data set
#' in the data/ folder
library(tidyverse)
# Load latest version (3) of the data set
raw_data <- readxl::read_xlsx("raw-data/Mimetas 8 factors masterfile v3E.xlsx")
chee_design <- readxl::read_xlsx("raw-data/design_chee_version.xlsx", sheet = 2)
# Rename data using letter code
full_data <- raw_data %>%
  select(
    Week, `Plate`, `Column (OW loc)`:`HBSS removal`, NTE:`Invasion Score`
  ) %>%
  rename(
    week = "Week",
    plate = "Plate",
    column = "Column (OW loc)",
    chip = "Chip (OW)",
    h = "Time on ice (min)",
    a = "Aliquot",
    b = "Collagen gel volume (µL)",
    d = "pH solution",
    c = "Amount mixing",
    g = "Starting time (min)",
    e = "HBSS Ca/Mg",
    f = "HBSS removal",
    insufficient.filling = "NTE",
    insufficient.cells = "Insufficent Cells",
    bubbles = "Bubble in MF(D8)",
    dead.cells = "Dead cells (D8)",
    teer = "TEER",
    fibrosity = "Fibrosity IDM (Gel D0)",
    fibrous = "Fibrous Visual (Gel D0)",
    invasion.score = "Invasion Score"
  ) %>%
  # Recode all variables in -1/+1 fashion
  mutate(
    # Plate number extracted from ID
    plate = as.numeric(str_extract(plate, "\\d$")),
    row = str_extract(chip, "\\w"),
    teer = as.numeric(gsub("No Fit", NA, teer)),
    h = recode(h, `1` = -1, `60` = 1),
    a = as.numeric(recode(a, "Early" = -1, "Late" = 1)),
    b = recode(b, `100` = -1, `300` = 1),
    d = recode(d, `7.1` = -1, `8.3` = 1),
    c = recode(c, `20` = -1, `50` = 1),
    g = recode(g, `10` = -1, `60` = 1),
    e = as.numeric(recode(e, "-/-" = -1, "+/+" = 1)),
    f = as.numeric(recode(f, "No" = -1, "Yes" = 1)),
    # Flag problematic cells
    problem = (bubbles | insufficient.filling),
    # Mutiply fibrosity by 1000
    fibrosity = fibrosity * 1000
  ) %>%
  relocate(row, .after = plate)

# Only fibrosity in the data and create a code to identify each row uniquely
fibrosity_no_tube <- full_data %>%
  select(
    -starts_with("insufficient"), -bubbles, -dead.cells,
    -invasion.score, -teer, -fibrous
  ) %>%
  unite("id", g, h, a, b, c, d, e, f, sep = ".", remove = FALSE)

# Join the tube numbers from Chee's version of the design
tube_subdesign <- chee_design %>%
  unite("id", Start:H_rmv, sep = ".", remove = TRUE) %>%
  mutate(tube = (Week - 1) * 8 + Tube) %>%
  select(id, tube)

fibrosity <- fibrosity_no_tube %>%
  left_join(tube_subdesign, by = "id") %>%
  select(-id) %>%
  relocate(tube, .after = plate)

# Save the dataset as rda file
save(fibrosity, file = "data/fibrosity.rda")

# Only the problematic cells and their location
problematic_chips <- full_data %>%
  select(
    week, plate, row, column, starts_with("insufficient"), bubbles,
    dead.cells
  )


# Save the dataset as rda
save(problematic_chips, file = "data/problematic_chips.rda")
