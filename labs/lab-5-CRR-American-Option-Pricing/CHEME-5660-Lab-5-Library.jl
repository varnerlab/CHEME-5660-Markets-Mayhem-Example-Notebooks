# ----------------------------------------------------------------------------------------------------- #
# Compute the expectation of X given the probability vector p
# ----------------------------------------------------------------------------------------------------- #
function E(X::Array{Float64,1},p::Array{Float64,1})::Float64
    return sum(X.*p)
end

# ----------------------------------------------------------------------------------------------------- #
# Compute the variance of X given the probability vector p
# ----------------------------------------------------------------------------------------------------- #
function Var(X::Array{Float64,1}, p::Array{Float64,1})::Float64
    return (E(X.^2,p) - (E(X,p))^2)
end

# ----------------------------------------------------------------------------------------------------- #
# Construct a dictionary holding the probability values for the nodes on each level of a binomial 
# lattice model with CRR values for (u,d,p)
# ----------------------------------------------------------------------------------------------------- #
function build_probability_dictionary(model::CRRLatticeModel, levels::Int64)::Dict{Int64, Array{Float64,1}}

    # initialize -
    probability_dict = Dict{Int64, Array{Float64,1}}()
    p = model.p

    for l = 0:levels
        
        # initialize -
        probability_array = Array{Float64,1}()
        
        # generate k range -
        karray = range(0,step=1,stop=l) |> collect

        for k ∈ karray
            tmp = binomial(l,k)*p^(k)*(1-p)^(l-k)
            push!(probability_array,tmp)
        end

        # grab the array - note: we have to reverse (d move is first, we need the other way arround)
        probability_dict[l] = reverse(probability_array)
    end

    # return -
    return probability_dict
end


# ----------------------------------------------------------------------------------------------------- #
# Construct a dictionary holding the node indexes for each level in a binomial tree with ud=1
# ----------------------------------------------------------------------------------------------------- #
function build_nodes_dictionary(levels::Int64)::Dict{Int64,Array{Int64,1}}

    # initialize -
    index_dict = Dict{Int64, Array{Int64,1}}()

    counter = 0
    for l = 0:levels
        
        # create index set for this level -
        index_array = Array{Int64,1}()
        for _ = 1:(l+1)
            counter = counter + 1
            push!(index_array,counter)
        end

        index_dict[l] = index_array
    end


    # return -
    return index_dict
end