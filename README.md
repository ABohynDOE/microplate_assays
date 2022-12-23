# Microplate assays analysis

Code for the analysis of the 2023 paper **"Design and analysis of a microplate assay in the presence of multiple restrictions in the randomization"**

## Code files

### R scripts

-   `1_data_processing.R`: Read the raw data provided by Mimetas, tidy it and save it into a `.rda` data set.

-   `2_error_structure.R`: Read the excel file containing the error structure of the experiment and save it into a `.rda` data set.

-   `3_active_effects.R`: Run the full linear model with 31 terms, corresponding to the 31 estimable factorial effects, and compute a robust estimate of the standard error in each error stratum. For each stratum, define the active effects based on the PSE(50) critical value at 10%, computed from the robust standard error estimate.

-   `4_position_plot.R`: Plot the fitted means for each column and row position, using the data from the mixed model, exported from Genstat. Both plots are saved in the `output/` folder.

-   `5_interaction_plot.R`: Generate the interaction plots for the three two-factor interaction that are active in the final model. All three plots are saved in the `output/` folder.

- `alternative_scenarios.R`: Generate the design files for the 3 alternative scenarios mentionned in the paper.

### Python scripts

#### Design generation

All files related to the generation of the design for the experiment.
In these files, we first start with a $8^12^6$ regular design in 32 runs generated using JMP, that uses the $2^{6-1}$ design with $f=abcde$ and the $W_1$-optimal blocking scheme of Mee (2009) to generate the 8 blocks.

- `1_txt2oa.py`: Convert the original $8^12^6$ design from JMP to an array object from the OApackage python package.

- `2_extend_OA.py`: Extend in all possible ways the $8^12^6$ to a $8^14^12^6$ by adding a four-level factor to the design.

- `3_regular_filter.py`: Filter all the $8^14^12^6$ designs generated previously to only keep the ones with regular aliasing among the factors.

- `4_aliasing.py`: Compute the aliasing between the 6 factors $a$ to $f$ (main effects, two-factor interactions and three-factor interactions) and the four-level factor defining the plates and the eight-level factor defining the 8 blocks for the column positions.

After generating the aliasing patterns of the three regular designs, we choose the best one as the design for the experiment.

#### Aliasing

All files related to the computation of the aliasing of factors and the error structure of the design

-   `column_position_pseudo_factor_aliasing.py`: Compute the aliasing of the 7 column position pseudo-factors $p_i$, with $i=1,\ldots,7$, that represents the 8 block over the columns of a plate, with the 6 main effects, 15 two-factor interactions and 20 three-factor interactions between the 6 factors $a$ to $f$. *No file output*.

-   `g_h_aliasing.py`: Compute the aliasing of the two whole plot factors ($g$ and $h$), with the with the 6 main effects, 15 two-factor interactions and 20 three-factor interactions between the 6 other factors of the design ($a$ to $f$). *No file output*.

-   `column_position_definition.py`: Print a table that shows how, for each plate, the 8 column positions on a plate, are defined by the three independent pseudo-factors $p_1$, $p_2$ and $p_3$. *No file output*.

