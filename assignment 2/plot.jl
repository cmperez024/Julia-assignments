# Add the packages

import Pkg
Pkg.add("SQLite")
Pkg.add("Tables")
Pkg.add("DBInterface")
Pkg.add("DataFrames")
Pkg.add("Gadfly")
Pkg.add("Cairo")
Pkg.add("Fontconfig")

# Use the packages
using SQLite
using Tables
using DBInterface
using DataFrames
using Gadfly
using Cairo
using Fontconfig

println("Packages checked. Beginning execution...")

# Parse commands
inputDB = ARGS[1]
searchName = ARGS[2]
searchSex = ARGS[3]

# Set name to lowercase then capitalize first letter
searchName = lowercase(searchName)
searchName = string(uppercase(searchName[1]), searchName[2:length(searchName)])
searchSex = uppercase(searchSex)

# Load database 
db = SQLite.DB(inputDB)

 #= 
 Query that performs an inner join from the sumfrequencies table to the df table.
 This is so that only years appearing with the nameData (non-zero frequencies) will be present
 with the corresponding total frequency count from that year

 First block corresponds to the sum of frequencies table (named A) and the second block
 is the table with entries for the desired name (named B)
=#
println("Executing query...")

df = DBInterface.execute(db, 
"SELECT A.year_, frequency_, sumFreq_ from
(SELECT year_, sum(frequency_) sumFreq_  from namedata
group by year_) as A

inner join (SELECT year_, frequency_ from nameData
where name_ == \"$(searchName)\" AND sex_ == \"$(searchSex)\" ) AS B

on B.year_ = A.year_
") |> DataFrame

println("Query executed.")

# Get relative frequency by dividing existing columns using broadcasted division
df.RelFreq = df.frequency_[:]  ./ df.sumFreq_[:]

sexLabel = ""
if searchSex == "M"
    sexLabel = "Male"
elseif searchSex == "F"
    sexLabel = "Female"
end

println("Plotting data...")

plot = Gadfly.plot(df, x=:year_, y=:RelFreq, Geom.point,
Guide.xlabel("Year", orientation=:horizontal), Guide.ylabel("Relative Frequency (per babies born each year)", orientation=:vertical),
Guide.title("Relative Frequency of $(sexLabel) Babies Named $(searchName)"))
draw(PNG("NameFrequency_$(searchName)_$(searchSex).png", 6inch, 6inch), plot)

println("File NameFrequency_$(searchName)_$(searchSex).png created.")