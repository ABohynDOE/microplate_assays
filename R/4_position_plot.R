library(tidyverse)

# Load the position effects
position_data <- readxl::read_excel("raw-data/fibrosity_position.xlsx")

# Compute error position
position_data <- position_data %>%
  group_by(position) %>%
  mutate(
    error.ymin = mean(size) - error / 2,
    error.ymax = mean(size) + error / 2
  )

# Rename row and column using 1 to 8 
row_label <- position_data %>% 
  filter(position == "row") %>% 
  pull(label) %>% 
  unique() %>% 
  sort() %>%
  as.character()

col_label <- position_data %>% 
  filter(position == "column") %>% 
  pull(label) %>% 
  as.integer() %>%
  unique() %>% 
  sort()

position_data <- position_data %>%
  mutate(
    label_base = label, 
    label = ifelse(
      position == "row",
      match(label_base, row_label),
      match(label_base, col_label)
      ),
    label = as.factor(label)
    )

# Unique position
unique_pos <- unique(position_data$position)
plot.list <- list()
index <- 1

# Plot the effects
for (pos in unique_pos) {
  # Actual plot of the data
  if (pos == "column") {
    sub_data <- position_data %>%
      filter(position == pos) %>%
      mutate(label = as.factor(as.numeric(label)))
  } else {
    sub_data <- position_data %>%
      filter(position == pos)
  }
  p <- sub_data %>%
    ggplot(
      aes(x = label, y = size, group = 1)
    ) +
    geom_point() +
    geom_line() +
    labs(
      x = str_to_title(pos),
      y = "Fibrosity"
    ) +
    # Add the error bar
    geom_errorbar(
      aes(
        x = 0.675,
        ymin = error.ymin,
        ymax = error.ymax
      ),
      width = 0.2
    ) +
    ylim(min(position_data$size), max(position_data$size)) +
    theme_bw() +
    theme(panel.grid = element_blank())
  # Save the plot
  ggsave(
    filename = sprintf("output/figures/%s_effect.pdf", pos),
    plot = p,
    width = 3,
    height = 3
  )
  # Store the plot inside the list
  plot.list[[index]] <- p
  index <- index + 1
}

# Combine the plots
g <- gridExtra::grid.arrange(
  plot.list[[2]],
  plot.list[[1]],
  nrow = 1
)

# Save the combined plot
ggsave(
  filename = "output/figures/position_plot.pdf",
  plot = g,
  width = 6.5,
  height = 3
)
