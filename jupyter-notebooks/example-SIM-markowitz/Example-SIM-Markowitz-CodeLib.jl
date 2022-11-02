abstract type AbstractReturnModel end

mutable struct SingleIndexModel <: AbstractReturnModel

    # model -
    α::Float64          # firm specific unexplained return
    β::Float64          # relationship between the firm and the market
    r::Float64          # risk free rate of return 
    ϵ::Distribution     # random shocks 

    # constructor -
    SingleIndexModel() = new()
end

function evaluate_model(model::SingleIndexModel, Rₘ::Array{Float64,1})::Array{Float64,1}

    # compute the model estimate of the excess retrurn for firm i -
    α = model.α
    β = model.β

    # compute ex return -
    R̂ = α .+ β .* Rₘ

    # return -
    return R̂
end

function sample_sim_model(model::SingleIndexModel, Rₘ::Array{Float64,1}; 𝒫::Int64 = 100)::Array{Float64,2}

    # compute the model estimate of the excess retrurn for firm i -
    α = model.α
    β = model.β
    ϵ = model.ϵ

    # how many time samples do we have?
    N = length(Rₘ)

    # generate noise array -
    W = rand(ϵ, N, 𝒫);

    # initialize some storage -
    X = Array{Float64,2}(undef, N, 𝒫);

    for t ∈ 1:N
        for p ∈ 1:𝒫
            X[t,p] = α + β*Rₘ[t] + W[t,p]
        end
    end

    # return -
    return X
end


function compute_minvar_portfolio_allocation(μ, Σ, target_return::Float64;
    w_lower::Float64 = 0.0, w_upper::Float64 = 1.0, wₒ::Float64 = 0.0, risk_free_return::Float64)

    # initialize -
    number_of_assets = length(μ)
    w = Variable(number_of_assets)
    risk = quadform(w,Σ)
    ret  = dot(w,μ) + wₒ*risk_free_return

    # setup problem -
    p = minimize(risk)
    p.constraints += [w_lower <= w, w <= w_upper, ret >= target_return, (wₒ + sum(w)) == 1.0]
    Convex.solve!(p, SCS.Optimizer(); silent_solver = true)

    # return -
    return (p.status, evaluate(w), p.optval, evaluate(ret))
end

function compute_excess_return(data_table::DataFrame, map::Pair{Symbol,Symbol}; rf::Float64 = 0.0403)

    # initialize -
    (number_of_rows, _) = size(data_table)
    return_table = DataFrame(timestamp = Date[], μ = Float64[], R = Float64[])

    # main loop -
    for row_index = 2:number_of_rows

        # grab the date -
        tmp_date = data_table[row_index, map.first]

        # grab the price data -
        yesterday_close_price = data_table[row_index-1, map.second]
        today_close_price = data_table[row_index, map.second]

        # compute the diff -
        μ = ((today_close_price - yesterday_close_price) / yesterday_close_price)*100
        R = μ - rf

        # push! -
        push!(return_table, (tmp_date, μ, R))
    end

    # return -
    return return_table
end

function compute_excess_log_return(data::DataFrame; 
	m::Int64 = 30, rf::Float64 = 0.0403)::Array{Float64,1}

	# sort the data (newest data on top)
	𝒫 = sort(data, [order(:timestamp, rev=true), :close]);
	
	# initialize -
	n = m + 2
	R = Array{Float64,1}(undef, m)

	# compute R -
	for i ∈ 1:m
		# compute the log return - and capture
		R[i] = log(𝒫[n-i,:close]/𝒫[n-i - 1,:close])
	end

	# return -
	return (R .- rf);
end;

function μ(models::Dict{String, SingleIndexModel}, Rₘ::Array{Float64,1}, ticker_array::Array{String,1})::Array{Float64,1}

    # initialize -
    μ_vector = Array{Float64,1}();

    # what the mean value for Rₘ -
    μₘ = mean(Rₘ);

    # process eack ticker -
    for ticker ∈ ticker_array
        
        # grab a model, and get the parameters -
        model = models[ticker];
        α = model.α
        β = model.β

        # compute -
        tmp = (α + β*μₘ);

        # grab -
        push!(μ_vector, tmp);
    end
        
    # return -
    return μ_vector;
end

function Σ(models::Dict{String, SingleIndexModel}, Rₘ::Array{Float64,1}, ticker_array::Array{String,1})::Array{Float64,2}
end