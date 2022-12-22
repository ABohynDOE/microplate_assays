# -*- coding: utf-8 -*-
"""
Compute the aliasing of the 8-lvl factor and the 4-lvl factor for the regular designs
enumerated previously

Created on Fri Mar  4 12:08:58 2022

@author: Alexandre Bohyn - alexandre dot bohyn [at] kuleuven dot be
"""
# %% Packages
import glob
import re

import numpy as np
import pandas as pd

def x2fx(mat: np.array, k: int):
    """Generate all interactions up to k-factors, of the columns of matrix"""
    max_k = min(mat.shape[1], k)
    n_cols = 0
    for i in range(1, max_k + 1):
        n_cols += comb(mat.shape[1], i)
    out = np.zeros((mat.shape[0], n_cols), dtype=int)
    labels = []
    index = 0
    for i in range(1, max_k + 1):
        for c in combinations(range(mat.shape[1]), i):
            int_mat = mat[:, c]
            labels.append("".join([chr(97 + i) for i in c]))
            out[:, index] = np.sum(int_mat, axis=1) % 2
            index += 1
    return out, labels


def unfold_factor(mat: np.array, n_levels: int, index: int):
    """
    Unfolds a factor of a design form n levels into log_2(n) two-level factors.
    The number of levels of the factor must be a power of two.
    The first level of factor has to be 0.
    The place of the factor in the design matrix in given by `index`
    """
    if n_levels not in [4, 8]:
        raise ValueError("Not implemented yet")
    # Extract factor to unfold
    parent_col = mat[:, index : index + 1]  # noqa: E203
    child_columns = np.zeros((mat.shape[0], int(np.log2(n_levels))), dtype=int)
    child_columns[:, 0:1] = parent_col > ((n_levels // 2) - 1)
    child_columns[:, -1:] = (parent_col % 2) == 1
    if n_levels == 8:
        child_columns[:, 1:2] = (parent_col // 2) % 2 == 1
    return child_columns

def main():
  file_names = glob.glob("raw-data/regular_designs/*.txt")
  # Table for the aliasing for plate factors only
  plate_aliasing = pd.DataFrame()
  for file_idx, file in enumerate(file_names):
      # Load the files
      matrix = np.loadtxt(file, delimiter=",", dtype=int)

      # 8-factor aliasing
      # Unfold the eight-level factor
      uf_8lvl = unfold_factor(matrix, 8, 0)
      # Compute all PF of the four-level factor
      pf_8lvl, label_pf_8lvl = x2fx(uf_8lvl, 3)

      # 4-factor aliasing
      # Unfold the four-level factor
      uf_4lvl = unfold_factor(matrix, 4, matrix.shape[1] - 1)
      # Compute all PF of the four-level factor
      pf_4lvl, label_pf_4lvl = x2fx(uf_4lvl, 2)

      # 3FI of two-level factors
      factors = matrix[:, 1:-1]
      # The unfolded 4-level factors are used as factor g
      factors = np.concatenate((factors, uf_4lvl), axis=1)
      fi_matrix, label_fi = x2fx(factors, 3)

      # Interactions between 1,2,3FI and
      # 8-level factor
      int_8lvl_3fi = np.matmul(pf_8lvl.T * 2 - 1, fi_matrix * 2 - 1)
      row, col = np.nonzero(int_8lvl_3fi)

      # Put all active interactions in a dictionnary
      aliasing = pd.DataFrame()
      for i, x in enumerate(row):
          row_string = label_pf_8lvl[x]
          block_string = "B_" + "".join(map(str, [ord(i) - 96 for i in row_string]))
          col_string = label_fi[col[i]]
          alias = {
              "stratum": "block",
              "block": block_string,
              "alias": col_string,
              "length": len(col_string),
          }
          aliasing = aliasing.append(alias, ignore_index=True)

      # Interactions between 1,2,3FI and
      # 4-level factor
      int_4lvl_3fi = np.matmul(pf_4lvl.T * 2 - 1, fi_matrix * 2 - 1)
      row, col = np.nonzero(int_4lvl_3fi)

      # Put all active interactions in the same dictionnary
      for i, x in enumerate(row):
          row_string = label_pf_4lvl[x]
          block_string = "P_" + "".join(map(str, [ord(i) - 96 for i in row_string]))
          col_string = label_fi[col[i]]
          alias = {
              "stratum": "plate",
              "block": block_string,
              "alias": col_string,
              "length": len(col_string),
          }
          plate_alias = {
              "design": f"Design {file_idx+1}",
              "plate": block_string,
              "alias": col_string,
              "length": len(col_string),
          }
          aliasing = aliasing.append(alias, ignore_index=True)
          plate_aliasing = plate_aliasing.append(plate_alias, ignore_index=True)

      # Reshape table
      aliasing_large = pd.pivot_table(
          aliasing,
          values="alias",
          index=["stratum", "block"],
          columns="length",
          aggfunc=lambda x: " ".join(x),
      )

      plate_aliasing_large = pd.pivot_table(
          plate_aliasing,
          values="alias",
          index=["design", "plate"],
          columns="length",
          aggfunc=lambda x: " ".join(x),
      )
      # Print aliasing table to Excel files
      single_file_name = re.search("(N32_.+)(\.txt)", file).group(1)
      excelfilename = f"output/tables/aliasing/aliasing_{single_file_name}.xlsx"
      aliasing_large.to_excel(excelfilename, index=True)
      
      common_file_name = re.search("(N32_.+)(_nbr)", file).group(1)
      plate_excelfilename = f"output/tables/aliasing/plate_aliasing_{common_file_name}.xlsx"
      plate_aliasing_large.to_excel(plate_excelfilename, index=True)

# %% Activation
if __name__ == "__main__":
  main()
    
