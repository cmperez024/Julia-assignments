When any program is ran, several packages may need to be installed.


To use prepare.jl, type:
julia prepare.jl names.zip databasename.db

It will first install necessary packages and then execute the code. After a small period of time, a database will be created in the same directory as the julia files.

Database may appear in files but will not be complete until the program states the database has been loaded. 


Then, to plot, use:
julia plot.jl databasename.db FirstName Sex

Sex must be a single character M for male, F for female.

The plots are based on the relative frequency of the name. That is, each point represents the frequecy of a name occuring that year, divided by the total number of babies in the data for that year. 

A PNG image will be created and placed in the same directory as the julia files. The image may appear, but will not be viewable until the program states that the file has been created.