# -*- coding: utf-8 -*-
"""
Extend the starting designs with a four-level factor.
All resulting designs are stored in a single file.

Created on Wed Feb 23 16:24:57 2022

@author: Alexandre Bohyn - alexandre dot bohyn [at] kuleuven dot be
"""
# % Packages
import contextlib
import glob
import os
import re
import oapackage as oa
import numpy as np

def main():
  # % Load the arrays
  file = "raw-data/designs/N32_8^1_2^6.oa"
  # Load design
  print(f"Reading file {file}")
  design = oa.readarrayfile(file)
  array = design[0].getarray()
  # Find levels
  levels = []
  for i in range(array.shape[1]):
      levels.append(len(np.unique(array[:, i])))
  # Add four for new colum
  levels.append(4)
  # Create the arrayclass
  arrayclass = oa.arraydata_t(levels, array.shape[0], 2, len(levels))
  # Extend the design
  with open(os.devnull, "w") as devnull:
      with contextlib.redirect_stdout(devnull):
          array_list_ext = oa.extend_arraylist(design, arrayclass)
  print(f"Extended with a 4-lvl factor into {len(array_list_ext)} designs")
  
  # Save the extended designs as OA file
  name = re.sub("2^6.oa", "2^6_4^1.oa", file)
  oa.writearrayfile(name, array_list_ext)
  print(f"All designs saved to {name}")
  
# % Activation
if __name__ == "__main__":
    main()
        
