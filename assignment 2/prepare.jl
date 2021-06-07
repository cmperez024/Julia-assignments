# Add the packages
import Pkg
Pkg.add("ZipFile")
Pkg.add("CSV")
Pkg.add("SQLite")
Pkg.add("Tables")
Pkg.add("DBInterface")

# Use the packages
using ZipFile
using CSV
using SQLite
using Tables
using DBInterface

println("Packages checked. Beginning execution...")

# Get input and output file names from command line
inputFile = ARGS[1]
outputFile = ARGS[2]

# Schema: name (String), sex (String), Frequency (integer), year (integer)
colNames = ["Name_", "Sex_", "Frequency_", "Year_"]
colTypes = [String, String, Int, Int]

# Prepare SQLite database, create the table using the above schema
db = SQLite.DB(outputFile)
SQLite.createtable!(db, "nameData", Tables.Schema(colNames, colTypes))

# Make a prepared statement
stmt = SQLite.Stmt(db,
"INSERT INTO nameData(Name_, Sex_, Frequency_, Year_) VALUES(?, ?, ?, ?)")

println("Database and prepared statement created.")

println("Parsing files..")

# Unzip and iterate through all files
zipped = ZipFile.Reader(inputFile)
for i in zipped.files

    # Process yob files only
    if occursin("yob", i.name)
    # Fetch year from filename
       tempYear = parse(Int, i.name[4:7]) # bounds inclusive

       # Read into a CSV
       csv = CSV.File(read(i), header=["Name_", "Sex_", "Frequency_"])


       # Run prepared statement for each line and begin the transaction
       SQLite.transaction(db)
       for row in csv
        DBInterface.execute(stmt, [row.Name_, row.Sex_, row.Frequency_, tempYear])
       end
       # End transaction
       SQLite.commit(db)

    end
 
end

# Close the zipfile
close(zipped)

# Completion message
println("Database loaded. Check local files.")