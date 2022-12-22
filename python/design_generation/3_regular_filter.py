# -*- coding: utf-8 -*-
"""
Filter the regular arrays among all extend arrays.

Created on Wed Feb 23 16:41:32 2022

@author: Alexandre Bohyn - alexandre dot bohyn [at] kuleuven dot be
"""
# % Packages
import glob
import re
import os

import numpy as np
import oapackage as oa

from itertools import combinations
from math import comb


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
  file = "raw-data/designs/N32_8^1_4^1_2^6.oa"
  array_list = oa.readarrayfile(file)
  regular_arrays = []
  for array in array_list:
      matrix = array.getarray()
      # PSEUDO FACTORS
      # Unfold the four-level factor
      uf_4lvl = unfold_factor(matrix, 4, matrix.shape[1] - 1)
      # Compute all PF of the four-level factor
      pf_4lvl, label_pf_4lvl = x2fx(uf_4lvl, 2)
      # Unfold the eight-level factor
      uf_8lvl = unfold_factor(matrix, 8, 0)
      # Compute all PF of the four-level factor
      pf_8lvl, label_pf_8lvl = x2fx(uf_8lvl, 3)
  
      # FULL 2FI MODEL
      # Join matrix and four-level factor
      factors = matrix[:, 1:-1]
      large_matrix = np.concatenate((factors, pf_4lvl), axis=1)
      full_2fi_matrix, label_full_2fi = x2fx(large_matrix, 2)
  
      # INTERACTIONS
      interaction_matrix = np.matmul(pf_8lvl.T * 2 - 1, full_2fi_matrix * 2 - 1)
      regular_flag = (
          (interaction_matrix == 0) | (interaction_matrix == 32)
      ).all()
  
      # Keep only the regular designs
      if regular_flag:
          regular_arrays.append(array)
  
  # Display details
  print(
      f"File {file}: {len(regular_arrays)} regular arrays among {len(array_list)}"
  )
  # Empty directory
  for f in glob.glob(
      f'raw-data/regular_designs/*'
  ):
      os.remove(f)
  
  # Save list to file
  for idx, array in enumerate(regular_arrays, start=1):
      matrix = array.getarray()
      name = (
          f'raw-data/regular_designs/N32_8^1_4^1_2^6_nbr{idx}.txt'
      )
      np.savetxt(name, matrix, delimiter=",", fmt="%.0f")
  print('Designs written to raw-data/regular')

# % Activation
if __name__ == "__main__":
    main()
    
