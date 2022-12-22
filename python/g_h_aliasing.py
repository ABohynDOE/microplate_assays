"""
Compute the aliasing of the two hard-to-change factors: g and h,
with the 6 easy-to-change factors: a,b,c,d,e,f

Print aliasing to the screen, create no file.

"""

# %% Packages

from itertools import combinations

import pandas as pd

def main():
  # Load the design
    design = pd.read_excel("raw-data/design_chee_version.xlsx", sheet_name=1)

    # Rename two-level factors to a->h
    design = design.rename(
        columns={
            "Start": "g",
            "Ice": "h",
            "Aliquot": "a",
            "Collagen": "b",
            "Mixing": "c",
            "pH": "d",
            "H_quant": "e",
            "H_rmv": "f",
        }
    )

    # Create all interactions between the factors a,b,c,d,e and f
    letters = [chr(97 + i) for i in range(6)]
    interaction_list = []
    for int_level in [2, 3]:
        c = combinations(letters, int_level)
        for interaction in c:
            name = "".join(interaction)
            interaction_list.append(name)
            sub_design = design[list(interaction)]
            design[name] = sub_design.prod(axis=1)

    # Compute the aliasing between interactions and g and h
    print("\nAliasing of the design:")
    for factor in ["g", "h"]:
        for interaction in interaction_list:
            aliasing = (design[factor] * design[interaction]).sum()
            if aliasing != 0:
                print(f"{factor} = {interaction}")

# %% Declaration
if __name__ == "__main__":
    main()
