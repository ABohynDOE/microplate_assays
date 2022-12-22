# microplate_assays
Code for the analysis of the 2023 paper "Design and analysis of a microplate assay in the presence of multiple restrictions in the randomization"

## Code files

### R scripts

- `1_data_processing.R`: Read the raw data provided by Mimetas, tidy it and save it into a `.rda` data set.

- `2_error_structure.R`: Read the excel file containing the error structure of the experiment and save it into a `.rda` data set.

- `3_active_effects.R`: Run the full linear model with 31 terms, corresponding to the 31 estimable factorial effects, and compute a robust estimate of the standard error in each error stratum. For each stratum, define the active effects based on the PSE(50) critical value at 10%, computed from the robust standard error estimate.

- `4_position_plot.R`: Plot the fitted means for each column and row position, using the data from the mixed model, exported from Genstat. Both plots are saved in the `output/` folder.

- `5_interaction_plot.R`: Generate the interaction plots for the three two-factor interaction that are active in the final model. All three plots are saved in the `output/` folder.


### Python scripts

- `column_position_pseudo_factor_aliasing.py`: Compute the aliasing of the 7 column position pseudo-factors $p_i$, with $i=1,\ldots,7$, that represents the 8 block over the columns of a plate, with the 6 main effects, 15 two-factor interactions and 20 three-factor interactions between the 6 factors $a$ to $f$. *No file output*.

-  `g_h_aliasing.py`: Compute the aliasing of the two whole plot factors ($g$ and $h$), with the  with the 6 main effects, 15 two-factor interactions and 20 three-factor interactions between the 6 other factors of the design ($a$ to $f$). *No file output*.

-`column_position_definition.py`: Print a table that shows how, for each plate, the 8 column positions on a plate, are defined by the three independent pseudo-factors $p_1$, $p_2$ and $p_3$. *No file output*.
