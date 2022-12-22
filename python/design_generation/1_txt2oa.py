"""
Convert the design from JMP (exported to a text file) to an OApackage array object.

Created on Wed Feb 23 16:24:57 2022

@author: Alexandre Bohyn - alexandre dot bohyn [at] kuleuven dot be
"""
import glob
import re
import pandas as pd
import numpy as np
import oapackage as oa

# Gather filenames
def main():
  file = "raw-data/designs/N32_8^1_2^6.txt"
  # Load file as a df
  df = pd.read_table(file, sep=",").filter(regex=r"^\w|B")
  levels = [df[i].nunique() for i in df.columns]

  # Convert columns to 0/1/2/3 and 0/1
  mat = np.array(df, dtype=int)
  for i, x in enumerate(levels):
      if x == 2:
          mat[:, i] = (mat[:, i] + 1) // 2
      else:
          mat[:, i] = mat[:, i] - 1

  # Convert to OA design
  des = oa.array_link(mat)
  desLMC = oa.reduceLMCform(des)

  # Save the design as OA file
  name = re.sub(".txt", ".oa", file)
  oa.writearrayfile(name, desLMC)
  print(f"Design in LMC form written in {name}")

if __name__ == "__main__":
    main()
        
