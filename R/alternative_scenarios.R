#' Generate the design matrices for the three alternative scenarios investigated
#' in the paper
library(tidyverse)
library(writexl)
# Create the design with basic factors a to e
basic_design <- matrix(nrow = 32, ncol = 5)
for (i in 1:5) {
  basic_design[, i] <- rep(c(rep(-1, 2**(5 - i)), rep(1, 2**(5 - i))), 2**(i - 1))
}
colnames(basic_design) <- letters[1:5]
basic_design <- tibble::as.tibble(basic_design)

# Gather information about the alternative scenarios in a tibble
scenarios_infos <- tibble::tibble(
  name = c("32_tubes", "no_restrictions", "four_level_blocking"),
  number = c(1, 2, 3),
  f = c("abcde", "abcd", "abcde"),
  g = c("ace", "abe", "abe"),
  h = c("abc", "ace", "abc"),
  week = c("ace", "abd", "abc"),
  plate = c("abc", "ade", "abe"),
  p1 = c("ab", "abc", "ab"),
  p2 = c("ce", "ad", "acd"),
  p3 = c("acd", "ae", NA),
  tube = c("abd", "abc", "abd")
)

# List of variables to create
vars <- scenarios_infos %>%
  select(-number, -name, -tube) %>%
  colnames()

# Function to turn an alias string into a proper factor, given the initial design
alias_to_factor <- function(data, alias) {
  vars <- str_split(alias, "") %>% unlist()
  data %>%
    select(all_of(vars)) %>%
    apply(1, prod)
}

# Function to turn an alias string into 8 different tube numbers
alias_to_tube <- function(data, alias) {
  vars <- str_split(alias, "") %>% unlist()
  sub_data <- data %>%
    select(all_of(vars))
  sub_data_mat <- as.matrix((sub_data + 1) / 2)
  num_mat <- 2**seq(dim(sub_data_mat)[2] - 1, 0)
  final <- (sub_data_mat %*% num_mat) + 1
  return(final[, 1])
}

# Case of the first scenario
for (i in 1:3) {
  # Isolate info on that design
  info <- scenarios_infos %>%
    filter(number == i)
  # Base design
  df <- basic_design
  # Generate all added factors
  for (var_name in vars) {
    if (i == 3 && var_name == "p3") {
      next
    }
    df <- df %>%
      mutate({{ var_name }} := alias_to_factor(df, info[[var_name]]))
  }
  # Generate the tube numbers
  df <- df %>%
    mutate(
      week_base = 4 * (week + 1),
      tube_base = alias_to_tube(df, info[["tube"]])
    ) %>%
    mutate(
      tube = week_base + tube_base,
      .keep = "unused"
    )
  # Reformat the week and plate, define the column positions
  df <- df %>%
    mutate(
      week = (week + 1) / 2 + 1,
      plate = 2 * (week - 1) + (plate + 1) / 2 + 1
    )
  if (i == 3) {
    df <- df %>%
      mutate(column = (p1 + 1) + (p2 + 1) / 2 + 1, .keep = "unused")
  } else {
    df <- df %>%
      mutate(column = 2 * (p1 + 1) + (p2 + 1) + (p3 + 1) / 2 + 1, .keep = "unused")
  }
  # Export to csv file
  writexl::write_xlsx(
    df,
    path = paste0("output/tables/alternative_scenario_", i, ".xlsx")
  )
}
