"""
Compute the aliasing of the 7 pseudo-factors  of the column positions with the
92 (8 ME + 28 2FI + 56 3FI) treatment effects and interactions.
Then link the treatments with the error stratum.

Print the results. Create no file.

Created on: 01/04/2022

Author: Alexandre Bohyn
"""
# %% Packages
from collections import defaultdict

import pandas as pd
import numpy as np
from itertools import combinations

# %% Declaration
if __name__ == "__main__":
    # Load design
    full_design = pd.read_excel(
        "raw-data/design_chee_version.xlsx", sheet_name=1)
    full_design_matrix = full_design.to_numpy(dtype=int)

    # Extract trmt factors and compute all 2FI, and all 3FI
    trmt_me_matrix = full_design_matrix[:, 4:]
    trmt_me_names = ["g", "h", "a", "b", "c", "d", "e", "f"]
    trmt_2fi_matrix = np.vstack(
        [
            trmt_me_matrix[:, i] * trmt_me_matrix[:, j]
            for i, j in combinations(range(trmt_me_matrix.shape[1]), 2)
        ]
    ).T
    trmt_3fi_matrix = np.vstack(
        [
            trmt_me_matrix[:, i] * trmt_me_matrix[:, j] * trmt_me_matrix[:, k]
            for i, j, k in combinations(range(trmt_me_matrix.shape[1]), 3)
        ]
    ).T
    trmt_matrix = np.concatenate(
        (trmt_me_matrix, trmt_2fi_matrix, trmt_3fi_matrix), axis=1
    )
    trmt_names = ["".join(c) for i in [1, 2, 3]
                  for c in combinations(trmt_me_names, i)]

    # Extract the column factor
    column = full_design_matrix[:, 2]
    # Unfold column factor into 3 pseudo-factors
    column_bf_matrix = (
        np.vstack(
            [
                column > 4,
                ((column - 1) // 2) % 2,
                column % 2 == 0,
            ]
        ).T
        * 2  # noqa: W503
        - 1  # noqa: W503
    )
    # Compute all interactions between pseudo-factors
    column_matrix = np.vstack(
        [
            np.prod(column_bf_matrix[:, c], axis=1)
            for i in [1, 2, 3]
            for c in combinations(range(3), i)
        ]
    ).T
    # Names of the interactions
    column_names = [
        ".".join([f"p{num}" for num in c])
        for i in [1, 2, 3]
        for c in combinations([1, 2, 3], i)
    ]
    column_names = [f"p{j} = " + x for j,
                    x in enumerate(column_names, start=1)]

    # Compute aliasing between the columns and the 31 d.f.
    column_aliasing = np.matmul(column_matrix.T, trmt_matrix) // 32
    col_vec, trmt_vec = np.nonzero(column_aliasing)
    column_aliasing_dict = defaultdict(list)
    for idx, col_idx in enumerate(col_vec):
        trmt_idx = trmt_vec[idx]
        col = column_names[col_idx]
        trmt = trmt_names[trmt_idx]
        column_aliasing_dict[col].append(trmt)

    print("6-factor aliasing:")
    for k, v in column_aliasing_dict.items():
        print(
            k,
            [
                "".join(sorted(i))
                for i in v
                if len(i) < 4 and "g" not in i and "h" not in i
            ],
        )

    print("\nFull 8 columns aliasing:")
    for k, v in column_aliasing_dict.items():
        print(k, ["".join(sorted(i)) for i in v if len(i) < 4])
