library(tidyverse)
library(latex2exp)
# Load the interaction data
interaction_data <- readxl::read_excel(
  path = "raw-data/fibrosity_interaction.xlsx",
  sheet = 1
) %>%
  # Compute interaction name
  mutate(interaction_label = paste0(factor1_label, factor2_label))
# Load the LSD (least significant difference) data
lsd_data <- readxl::read_excel(
  path = "raw-data/fibrosity_interaction.xlsx",
  sheet = 2
) %>%
  # Average per interaction
  group_by(interaction_label) %>%
  summarise(mean.error = mean(value)) %>%
  # gh is not estimable so we remove the LSD data
  mutate(mean.error = ifelse(interaction_label == "hg", NA, mean.error))

# Combined dataset
combined_data <- interaction_data %>%
  # Merge average LSD to interaction data
  full_join(lsd_data, by = "interaction_label") %>%
  # Compute a single error interval per interaction
  group_by(interaction_label) %>%
  mutate(
    error.y = mean(value),
    error.ymin = error.y - mean.error / 2,
    error.ymax = error.y + mean.error / 2
  )

# Function to use full label names instead of letters
fix_labels <- function(x) {
  switch(x,
    "a" = "Aliquot",
    "c" = "Amount of mixing",
    "d" = "pH",
    "g" = "Starting\ntime (min)",
    "h" = "Time on ice (min)"
  )
}

fix_levels <- function(level, factor) {
  out <- switch(factor,
    "a" = ifelse(level == "Low", "Early", "Late"),
    "c" = ifelse(level == "Low", "20", "50"),
    "d" = ifelse(level == "Low", "7.1", "8.3"),
    "g" = ifelse(level == "Low", "10", "60"),
    "h" = ifelse(level == "Low", "1", "30")
  )
  return(out)
}


# All interaction labels
interaction_labels <- unique(lsd_data$interaction_label)
# Plot list to hold the plots
plot.list <- list()
index <- 1
for (label in interaction_labels) {
  label1 <- substr(label, 1, 1)
  label2 <- substr(label, 2, 2)
  p <- combined_data %>%
    filter(interaction_label == label) %>%
    ggplot(
      aes(x = factor1_level, y = value, group = factor2_level)
    ) +
    # Point and line with type and shape specific to factor 2
    geom_point(aes(shape = factor2_level)) +
    geom_line(aes(lty = factor2_level)) +
    # Single average error bar for the whole plot
    geom_errorbar(aes(
      # Because the first point is located at x=1
      x = 0.6,
      ymin = error.ymin,
      ymax = error.ymax
    ),
    width = 0.15
    ) +
    # Re-order the labels in the x axis
    scale_x_discrete(
      name = fix_labels(label1),
      limits = c("Low", "High"),
      labels = c(fix_levels("Low", label1), fix_levels("High", label1))
    ) +
    scale_y_continuous(
      name = "Fibrosity",
      limits = c(
        min(combined_data$value),
        max(combined_data$value)
      )
      # Expand the frame on the top to fit the legend box
      # expand = expansion(mult = c(0.05, 0.2))
    ) +
    # Reordering of the items in the legend
    scale_linetype_discrete(
      name = fix_labels(label2),
      limits = c("Low", "High"),
      labels = c(fix_levels("Low", label2), fix_levels("High", label2))
    ) +
    # Reorder both legend part to combine them
    scale_shape_discrete(
      name = fix_labels(label2),
      limits = c("Low", "High"),
      labels = c(fix_levels("Low", label2), fix_levels("High", label2))
    ) +
    # Vertical box for interaction plot
    theme_bw() +
    theme(
      axis.text = element_text(size = 12),
      legend.position = "top",
      panel.grid = element_blank()
    )
  # Save the plot
  ggsave(
    filename = sprintf("output/figures/interaction_plot_%s.pdf", label),
    plot = p,
    width = 2.75,
    height = 4
  )
  # Store the plot inside the list
  plot.list[[index]] <- p
  index <- index + 1
}

# Combine the plots
g <- gridExtra::grid.arrange(
  plot.list[[3]], # gh
  plot.list[[2]], # ah
  plot.list[[1]], # cd
  nrow = 1
)

# Save the combined plot
ggsave(
  filename = "output/figures/interaction_plot_combined.pdf",
  plot = g,
  width = 8,
  height = 5
)
