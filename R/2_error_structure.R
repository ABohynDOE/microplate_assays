#' Read the raw file containing the error structure of the experiment, tidy it 
#' and save it as an .rda data set in the data/ folder.
library(tidyverse)
# Load error table
raw_error <- readxl::read_excel("raw-data/error_stratum_aliasing.xlsx")

# Clean up the data
error <- raw_error %>%
  # Separate column aliasing into a column for each alias
  separate(
    block, into = c("col_pos"), sep = ",", remove = T, extra = "drop"
  ) %>%
  # Re code the column pseudo-factors
  mutate(
    col_pos = recode(
      col_pos,
      'c1' = 'p_1',
      'c2' = 'p_6',
      'c3' = 'p_3',
      'c1.c2' = 'p_7',
      'c1.c3' = 'p_5',
      'c2.c3' = 'p_4',
      'c1.c2.c3' = 'p_2')
  ) %>%
  unite("aliasing", M.E, `2FI`, `3FI`, `col_pos`, na.rm = T, sep = ', ') %>%
  separate(
    aliasing, into = c('first_int'), sep = ',', extra = 'drop', remove = F
  ) %>%
  mutate(len = str_count(first_int)) %>%
  arrange(global_stratum, len, first_int) %>%
  select(global_stratum, aliasing, first_int)

# Save as error 
save(error, file="data/fibrosity_error.rda")
