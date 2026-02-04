import sys
import pandas as pd
import glob
import os

def mega_join(base_file):
    output_file = base_file + ".final"
    # Load the base UUID list (the 'annotated' file)
    # Using sep='\s+' to handle both tabs and spaces robustly
    df = pd.read_csv(base_file, sep='\s+', header=None, names=['uuid']).set_index('uuid')
    fns = sorted(glob.glob("*.tmp_join"))
    print(len(fns))
    for f in fns:
        try:
            anno = pd.read_csv(f, sep='\s+', header=None)
            
            # Rename first column to 'uuid' for the merge key
            cols = {0: 'uuid'}
            # Give unique names to other columns to avoid collisions
            for i in range(1, len(anno.columns)):
                cols[i] = f"{f}_col_{i}"
            anno.rename(columns=cols, inplace=True)
            anno.set_index('uuid')
            # Left Join: Keep all rows from df, add matches from anno
            df = pd.merge(df, anno, on='uuid', how='left')
        except Exception as e:
            print(f"Warning: Error processing {f}: {e}")

    # Replace missing values (NaN) with "0" as per your original requirement
    df.fillna("0", inplace=True)
    
    # Save as a clean, tab-separated file without index or headers
    df.to_csv(output_file, sep='\t', index=False, header=False)

if __name__ == "__main__":
    mega_join(sys.argv[1])