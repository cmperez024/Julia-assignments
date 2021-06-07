Requires data file from assignment 2. Must be named "names.db"

For some issue likely pertaining to the way Julia handles threading,
it is possible that an array indexing error will occur. This occurrence
is rare, and the issue is usually resolved by running the program again.

To use Julia with multithreading, type in the commmand line:
julia --threads number_of_threads assignment3.jl

The bonus problem is attempted, and its running is denoted by "Begin bonus"
printed to the console. "Bonus 50% Complete" refers to each partition's top 1000
having been computed. After, a heap of 1000 elements will be maintained to get 
the overall top 1000. 1000 entries will be displayed as
"CosineSimilarity BoyName GirlName".

On my machine running with 12 threads and benchmarking with @time, the whole 
program (including bonus) took about 38 seconds. With no threads, it took about
88 seconds.


