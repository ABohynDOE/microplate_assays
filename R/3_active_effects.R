#' Compute the effect size for the 31 factorial effects, along with robust
#' standard error estimate to identify the active effects in each stratum.
#' Save the active effects to and .rda data set and plot a dotplot of all the
#' effects.

library(tidyverse)

# Load the fibrosity data
load("data/fibrosity.rda")

# Load the error structure
load("data/fibrosity_error.rda")

# Build the linear model formula
formula <- str_split(error$first_int, "") %>%
  lapply(FUN = function(x) paste(x, collapse = ":")) %>%
  unlist() %>%
  paste(collapse = " + ") %>%
  paste("fibrosity ~", .)

# Function to sort effect names
strSort <- function(x) {
  sapply(lapply(strsplit(x, NULL), sort), paste, collapse = "")
}

# Extract sub data for the linear modelling (only rows without problems)
subdata <- fibrosity %>%
  filter(row %in% c("F", "L")) %>%
  select(row, a, b, c, d, e, f, g, h, fibrosity) %>%
  pivot_wider(
    names_from = row,
    names_prefix = "row",
    values_from = fibrosity
  ) %>%
  rowwise() %>%
  mutate(fibrosity = (rowF + rowL) / 2, .keep = "unused")

# Build the linear model and extract the coefficients
model <- data.frame("size" = lm(data = subdata, formula)$coefficients) %>%
  rownames_to_column(var = "effect") %>%
  mutate(
    effect = str_remove_all(effect, ":")
  )

# Sort the effect names
model$effect <- unlist(lapply(model$effect, strSort))
# Join the strata to the effects
model <- model %>%
  full_join(error, by = c("effect" = "first_int"))

# Compute PSE50
pse <- model %>%
  # Remove intercept line
  filter(!is.na(global_stratum)) %>%
  group_by(global_stratum) %>%
  mutate(
    # Absolute contrasts
    abs_size = abs(size),
    # Initial estimate of s.e. using 50 % quantile
    s_ini = 3.707 * quantile(abs_size, probs = 0.5),
    # Retain values lower than the initial estimate
    kept_values = ifelse(abs_size > s_ini, NA, abs_size),
    # Compute median of the retained values
    med = quantile(kept_values, 0.5, na.rm = T),
    # Final estimate of S.E. based on median of remaining contrasts and
    # consistency constant
    se = 1.484 * med,
    # Define consistency constant based on the number of contrasts (see paper
    # for values of cc2)
    cc2 = 1.71,
    # Compute final cut-off value
    cut_off = cc2 * se,
    # Active effects have size larger than cut_off value
    # Boolean variable to see which effect are active
    active_effect = (abs_size > cut_off | n() < 3),
    # Active labels used in ggplot for labeling
    active_label = ifelse(abs_size > cut_off | n() < 3, effect, NA)
  )

# Save effect size, estimated SE and thresholds to data file
active <- pse %>%
  select(effect, size, global_stratum, se) %>%
  rename(stratum = global_stratum) %>%
  mutate(se = ifelse(stratum == "week" | stratum == "week.plate", NA, se))
save(active, file = "data/active_effects.rda")

# Save effect sizes to excel
output_data <- pse %>%
  select(effect, size, global_stratum, se, cut_off) %>%
  mutate(across(where(is.numeric), function(x) round(x, 2)))

# Determine ideal bin width for dot plot
bin.width <- (range(pse$size)[2] - range(pse$size)[1]) / 150

# Stacked dot plot without legend
pse %>%
  # Replace 3fi labels for the column positions
  mutate(label = str_replace_all(
    active_label,
    c(
      "cdg" = "p[5]",
      "fgh" = "p[7]",
      "dgh" = "p[3]"
    )
  )) %>%
  ggplot(aes(
    x = factor(global_stratum),
    y = size,
    label = label
  )) +
  geom_dotplot(
    aes(
      colour = active_effect,
      fill = active_effect
    ),
    binaxis = "y",
    stackdir = "center",
    binwidth = bin.width,
    binpositions = "all"
  ) +
  ggrepel::geom_text_repel(
    box.padding = 0.5,
    max.overlaps = Inf,
    min.segment.length = 0,
    na.rm = TRUE,
    parse = TRUE
  ) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_x_discrete(
    name = "",
    limits = rev(c("week", "week.plate", "week.tube", "week.plate.tube")),
    labels = rev(c(
      "Week",
      "Plate",
      "Tube",
      "Unit"
    ))
  ) +
  scale_colour_manual(
    aesthetics = c("color", "fill"),
    values = c("grey50", "red"),
    breaks = c(FALSE, TRUE)
  ) +
  coord_flip() +
  labs(
    y = "Effect size"
  ) +
  theme_bw() +
  theme(
    legend.position = "none",
    text = element_text(size = 15)
  )

# Save plot to pdf
ggsave("output/figures/dotplot_fibrosity_no_legend.pdf",
  width = 8, height = 2.5
)
