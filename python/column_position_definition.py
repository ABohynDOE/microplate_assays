"""
Checks the aliasing of the column number with the pseudo-factors of the column position blocking.

Print results, create no file.
"""

import pandas as pd

if __name__ == "__main__":
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

    # Create the three independent factorial effects p_i
    design["p1"] = design["a"] * design["b"]
    design["p2"] = design["c"] * design["e"]
    design["p3"] = design["a"] * design["c"] * design["f"]

    # For each plate print sub design
    for plate_num in [1, 2, 3, 4]:
        print(f"\nPlate number {plate_num}:")
        sub_design = design[design["Plate"] == plate_num][
            ["p1", "p2", "p3", "Column"]
        ].sort_values(by=["Column"])
        print(sub_design)
