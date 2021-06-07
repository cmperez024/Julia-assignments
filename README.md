# Julia-assignments
Collection of data science assignments in Julia


## Assignment 2
Analysis of data containing baby names. Tasks were to first
- Read input file and output file from command line
- Use a library to scan the zip file
- Use a library to interface with SQLite3
- Create an SQLite table and filling its contents by scanning the csv's in the zip file

then
- Parse a command line phrase to extract input
- Establish connection to a database file
- Query the database to get corresponding data to plot


## Assignment 3
Further analysis of baby names, containing applications of linear algebra, and parallezation to speed up processing.
- Load data
- Determine distinct boy and girl names
- Build a bi-directional map from boy name and indices, and girl name to indices
- Initialize matrices that are dimensionalized by the number of boy and girl names
- Scan the data frame to add counts to the matrices
- Compute probability matrices by dividing by the total number of children in a given year
- Compute matrices that normalize values across years to be between 0 and 1
- Compute cosine distance between all pairs of boy and girl names. This step required splitting the matrices into 10 fragments then parallelizing the multiplications.
- Display name wiht largest cosine distance

The bonus asked to compute the top 1000 distances. I developed an algorithm by hand for this that efficiently computed the result within the same order of magnitude of the previous computation local to my machine.

## Assignment 4
Jupyter notebook file containing analysis of datasets from the UCI data repository. The following datasets were analyzed:
- Car evaluation
- Abalone
- Madelon
- KDD Cup 1999

For types of models were created for each of the datasets (16 models in total)
- Naive Bayesian classifier
- Classification tree
- Support vector machine
- Neural network

Training and testing time, as well as accuracy, were recorded in a table.

## Assignment 5
Usage of clustering techniques on a 27-dimensional cancer dataset.
- Categorical attributes were transformed into a 0 to 1 scale
- Numerical attributes were scaled to 0 to 1
- Use a variety clustering and gaussian mixture models to predict cancer stage

## Asssignment 6
Applying Principle Component Analysis to the cancer dataset used in the previous assignment
- Data separated into training and testing subsets
- PCA ran on all floating point features to produce a subset of PCA features
- Classifcation model trained and tested on transformed data 
- Change number of PCA features to extract and create graphs reporting classifier error as a number of selected features

