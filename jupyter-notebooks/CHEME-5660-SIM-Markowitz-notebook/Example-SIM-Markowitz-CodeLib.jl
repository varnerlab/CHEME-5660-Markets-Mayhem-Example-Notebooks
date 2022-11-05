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

function compute_minvar_portfolio_allocation_risk_free(μ, Σ, target_return::Float64;
    w_lower::Float64 = 0.0, w_upper::Float64 = 1.0, risk_free_return::Float64 = 0.001)

    # initialize -
    number_of_assets = length(μ)
    w = Variable(number_of_assets)
    risk = quadform(w,Σ)
    ret  = dot(w,μ) + (1-sum(w))*risk_free_return

    # setup problem -
    p = minimize(risk)
    p.constraints += [w_lower <= w, w <= w_upper, ret >= target_return]
    Convex.solve!(p, SCS.Optimizer(); silent_solver = true)

    # return -
    return (p.status, evaluate(w), p.optval, evaluate(ret))
end

function compute_minvar_portfolio_allocation(μ, Σ, target_return::Float64;
    w_lower::Float64 = 0.0, w_upper::Float64 = 1.0, wₒ::Float64 = 0.0, risk_free_return::Float64 = 0.001)

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

function compute_excess_return(data::DataFrame; 
	m::Int64 = 30, rf::Float64 = 0.0403)::Array{Float64,1}

	# sort the data (newest data on top)
	𝒫 = sort(data, [order(:timestamp, rev=true), :close]);
	
	# initialize -
	n = m + 2
	R = Array{Float64,1}(undef, m)

	# compute R -
	for i ∈ 1:m
		# compute the log return - and capture
		# R[i] = log(𝒫[n-i,:close]/𝒫[n-i - 1,:close])
        R[i] = ((𝒫[n-i,:close] - 𝒫[n-i - 1,:close])/(𝒫[n-i - 1,:close]) - rf)*100;
	end

	# return -
	return R;
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

    # how many tickers are going to look at?
    Nₐ = length(ticker_array);

    # initialize -
    Σ_array = Array{Float64,2}(undef, Nₐ, Nₐ);

    # compute the std of the market -
    σₘ = std(Rₘ);

    # main loop -
    for i ∈ 1:Nₐ

        # outer ticker -
        outer_ticker = ticker_array[i]
        outer_model = models[outer_ticker]
        βᵢ = outer_model.β;
        σᵢ_noise = std(outer_model.ϵ);

        for j ∈ 1:Nₐ
            
            # inner ticker -
            inner_ticker = ticker_array[j]
            inner_model = models[inner_ticker]
            βⱼ = inner_model.β;
        
            # compute Σ -
            if (i == j)
                Σ_array[i,j] = βᵢ^2*(σₘ)^2 + (σᵢ_noise)^2;
            else
                Σ_array[i,j] = βᵢ*βⱼ*(σₘ)^2;
            end
        end
    end

    # return -
    return Σ_array
end