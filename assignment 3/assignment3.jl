import Pkg
# Pkg.add("SQLite")
# Pkg.add("Tables")
# Pkg.add("DataFrames")
# Pkg.add("DBInterface")
# Pkg.add("LinearAlgebra")
# Pkg.add("DataStructures")


# Use the packages
using SQLite
using Tables
using DataFrames
using DBInterface 
using LinearAlgebra
using DataStructures

println("\nUsing $(Threads.nthreads()) threads\n")
println("Begin dataframe management")

# 1. Load the database into a dataframe =========================================

db = SQLite.DB("names.db")
df = DBInterface.execute(db, "SELECT * FROM nameData") |> DataFrame

# 2. Determine distinct years, boy names, and girl names ========================

# Unique years and number
uniqueYears = DataFrames.select(DataFrames.unique(df, "Year_"), "Year_")
Ny = DataFrames.nrow(uniqueYears)

# Get unique Name_ & Sex_ pairs and only select these columns
uniqueNames = DataFrames.select(DataFrames.unique(df, ["Name_", "Sex_"]), ["Name_", "Sex_"])

girlNames = DataFrames.select(DataFrames.filter(row -> row.Sex_ == "F", uniqueNames), "Name_")
Ng = DataFrames.nrow(girlNames)

boyNames = DataFrames.select(DataFrames.filter(row -> row.Sex_ == "M", uniqueNames), "Name_")
Nb = DataFrames.nrow(boyNames)

# 3. Bidirectional maps ==========================================================

# Before assigning values, first sort the names
# DataFrames.sort!(girlNames)
# DataFrames.sort!(boyNames)
DataFrames.sort!(uniqueYears)

# Create girl dictionary (NtI => Name to Index)
F_NtI = Dict(girlNames[i, 1] => i for i = 1:Ng)
F_ItN = Dict(i => girlNames[i, 1] for i = 1:Ng)

# Create boy dictionary
M_NtI = Dict(boyNames[i, 1] => i for i = 1:Nb)
M_ItN = Dict(i => boyNames[i, 1] for i = 1:Nb)

# Year dictionary (YtI => Year to index)
Y_YtI = Dict(uniqueYears[i, 1] => i for i = 1:Ny)
Y_ItY = Dict(i => uniqueYears[i, 1] for i = 1:Ny)

println("Size of dictionaries (B, G): $(Nb), $(Ng)")


println("End dataframe management\n")


# 4. Initialize matrices ==============================================
Fg = zeros(Float32, Ng, Ny)
Fb = zeros(Float32, Nb, Ny)

# 5. Add counts to matrices Fb and Fg ==================================
# Each row represents a name. Each year represents the count.
println("Begin F loop")
for i in 1:nrow(df)
    if df[i, "Sex_"] == "F"
        yearIndex = Y_YtI[df[i, "Year_"]]
        nameIndex = F_NtI[df[i, "Name_"]]
        Fg[nameIndex, yearIndex] = df[i, "Frequency_"]
    elseif df[i, "Sex_"] == "M"
        yearIndex = Y_YtI[df[i, "Year_"]]
        nameIndex = M_NtI[df[i, "Name_"]]
        Fb[nameIndex, yearIndex] = df[i, "Frequency_"]
    end
end
println("End F loop\n")

# 6. Children born every year ==============================================
# Initialize zero vector
Ty = zeros(Ny)
println("Begin T loop")
for i in 1:nrow(df)
    # Get year and its index
    yearIndex = Y_YtI[df[i, "Year_"]]
    Ty[yearIndex] += df[i, "Frequency_"]
end
println("End T loop\n")

# 7. Normalized matrices ===================================================
Pg = copy(Fg)
Pb = copy(Fb)

# ./= broadcast division and set LHS equal to this result
println("Begin P loop")
for i in 1:size(Pg, 1)
    Pg[i, :] ./= Ty
end

for i in 1:size(Pb, 1)
    Pb[i, :] ./= Ty
end
println("End P loop\n")

# # check if sum to 1
# for i in 1:Ny
#     yearSum = sum(Pg[:, i]) + sum(Pb[:, i])
#     if yearSum != 1.0
#         println(yearSum)
#     end
# end

# 8. Qb and Qg, normalize rows to L2 ====================================
Qg = copy(Pg)
Qb = copy(Pb)

println("Begin Q loop")
for i in 1:size(Qg, 1)
    Qg[i, :] = LinearAlgebra.normalize(Qg[i, :], 2)
end


for i in 1:size(Qb, 1)
    Qb[i, :] = LinearAlgebra.normalize(Qb[i, :], 2)
end
println("End Q loop\n")

# for i in size(Qb, 1)
# #     if norm(Qb[i, :], 2) != 1.0
# #         print(norm(Qb[i, :], 2))
# #     end
# end

# 9. Cosine distance, break into 10 fragments =============================


# Create 10 roughly equal intervals to partition Qb and Qg
QgIntervals = []
QbIntervals = []

global prevG = 0
global prevB = 0


println("Begin interval creation")
# Make sure integers are pushed so that one may use them to index
for i in 1:10
    intervalG = [Int64(prevG + 1), Int64(prevG + floor(Ng / 10))]
    push!(QgIntervals, intervalG)
    global prevG = prevG + floor(Ng/10)
    
    intervalB = [Int64(prevB + 1), Int64(prevB + floor(Nb / 10))]
    push!(QbIntervals, intervalB)
    global prevB = prevB + floor(Nb/10)
end
println("Interval numbers (B, G): $(length(QbIntervals)), $(length(QgIntervals))")
println("End interval creation\n")
# correct final interval
QgIntervals[10][2] += (Ng - QgIntervals[10][2])
QbIntervals[10][2] += (Nb - QbIntervals[10][2])


# Q_Views will contain the partioned matrices. Using views to conserve memory
global QgViews = []
global QbViews = []



# Push in the views into the list of views
# Index from 1st entry of ith interval to 2nd entry of ith interval
println("Begin view pushing")
for i in 1:10
    push!(QgViews, @view Qg[QgIntervals[i][1]:QgIntervals[i][2], :])
    push!(QbViews, @view Qb[QbIntervals[i][1]:QbIntervals[i][2], :])
end

println("View numbers (B, G): $(length(QbViews)), $(length(QgViews))")
println("End view pushing\n")





# Calculate the ith partition of Qb times the transpose of the jth partition of Qg 
# Do this for all pairs of i, j from 1 to 10. There will be 100 computations total
# After compuating, compare to the max, then save i,j partition information, as well as
# the subindex.
global maxDot = 0
global boyPartition = 0
global girlPartition = 0
global boySubindex = 0
global girlSubindex = 0

println("Begin matrix multiplication and search")

for i in 1:10
    Threads.@threads for j in 1:10

        product = QbViews[i] * transpose(QgViews[j])

        foundMax = findmax(product)
    
        if foundMax[1] > maxDot
            global boyPartition = i
            global girlPartition = j

            global boySubindex = foundMax[2][1]
            global girlSubindex = foundMax[2][2]

            global maxDot = foundMax[1]
        end
    end
end
println("End matrix multiplication and search\n")


# Using the partition information, restore the parent indexing.
# The subindex is relative to the start of the ith partition's interval, 
# so that the parent index is:
#       start of ith interval + subindex  - 1

boyNameIndex =  QbIntervals[boyPartition][1] + boySubindex - 1
girlNameIndex = QgIntervals[girlPartition][1] + girlSubindex - 1

boyNameMax = M_ItN[boyNameIndex]
girlNameMax = F_ItN[girlNameIndex]


println("Boy name: $(boyNameMax)\nGirl name: $(girlNameMax)\nCosine similarity: $(maxDot)")
println("boyIndex = $(boyNameIndex)\tgirlIndex = $(girlNameIndex)\n")




# Bonus ============================================
# Use a heap structure

# Min-max heap allows for comparison of minimum and maximum to easily maintain 1000 elements

println("Begin bonus\n")

# Get index of entry n from product given i and j partition
# This is based on flattening 2D matrix into 1D vector column by column using vec()
# In a product matrix, boy names correspond to row and girl names correspond to column
function getIndex(n, product, i, j)

    boyL = size(product, 1)
    girlL = size(product, 2)
    
    boyStart = QbIntervals[i][1]
    boyEnd = QbIntervals[i][2]
    girlStart = QgIntervals[j][1]
    
    
    # Two cases. Element is at bottom-most row, or not
    # If at bottom row, floor(n/boyL) == n/boyL 
    col = 0
    row = 0
    if floor(n/boyL) != n/boyL
        col = Int64(floor(n/boyL) + girlStart)
        row = Int64(n % boyL - 1 + boyStart)
    else
        col = Int64(floor(n/boyL) + girlStart - 1)
        row = boyEnd
    end 
    
    return (row, col)
end

collectedLists = []

for i in 1:10
    Threads.@threads for j in 1:10

        # Calculate product matrix
        product = QbViews[i] * transpose(QgViews[j])
    
        # Flatten the product to 1D, column-by-column
        Vprod = vec(product)
                
        # Return indices of top 1000 elements 
        partial = partialsortperm(Vprod, 1:1000, rev = true)
        
        # Convert indices into tuples of parent (boyIndex, girlindex) coordinates
        lists = [getIndex(n, product, i, j) for n in partial]
        
        push!(collectedLists, collect(zip(Vprod[partial], lists)))
    end
end

println("Bonus 50% complete\n")

# Create heap that allows extract of max and min to maintain size of 1000
heap = BinaryMinMaxHeap{Tuple{Float32,Tuple{Int64,Int64}}}()

for tempList in collectedLists 
    for tempTuple in tempList
        if length(heap) < 1000
            push!(heap, tempTuple)
        else
            min = minimum(heap)[1]
            # Replace value if current value is greater than min
            if tempTuple[1] > min
                popmin!(heap)
                push!(heap, tempTuple)
            end
        end
    end
end


# Get max elements from heap
top1000 = popmax!(heap, 1000)
for i in 1:1000
    dot = top1000[i][1]
    boyName = M_ItN[top1000[i][2][1]]
    girlName = F_ItN[top1000[i][2][2]]

    space = repeat(" ", 17 - length(boyName))

    println("$(dot)\t$(boyName)$(space)$(girlName)")
end

println("End bonus")