# Add the packages
import Pkg
Pkg.add("ZipFile")
Pkg.add("CSV")
Pkg.add("SQLite")
Pkg.add("Tables")
Pkg.add("DataFrames")

# Use the packages
using ZipFile
using CSV
using SQLite
using Tables
using DataFrames

# Get input and output file names from command line
inputFile = ARGS[1]
outputFile = ARGS[2]

# Schema: name (String), sex (String), Frequency (integer), year (integer)
colNames = ["Name_", "Sex_", "Frequency_", "Year_"]
colTypes = [String, String, Int, Int]

# Prepare SQLite database, create the table using the above schema
db = SQLite.DB(outputFile)
SQLite.createtable!(db, "nameData", Tables.Schema(colNames, colTypes))


# Unzip and iterate through all files
zipped = ZipFile.Reader(inputFile)
for i in zipped.files

    # Process yob files only
    if occursin("yob", i.name)
    # Fetch year from filename
       tempYear = parse(Int, i.name[4:7]) # bounds inclusive

       # Read csv, pipe into a dataframe. Add a column year. Then add to table.
       df = CSV.File(read(i), header=["Name_", "Sex_", "Frequency_"]) |> DataFrame
       df.Year_ = repeat([tempYear], nrow(df))
       SQLite.load!(df, db, "nameData")
    end
 
end

# Completion message
println("Database loaded. Check local files.")
