CLI args:
-l (line count to read) : usize
-o (start offset) : usize
-m (minified) : bool
-s (separator) : char

ex.) cat myfile.csv | csvjson -l=10 -o=20 -m -s=,
yields -> read ten lines of a comma separated file starting from the 20th line + print each object per line
