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

function compute_realized_return(data::Dict{String, DataFrame}, ticker_array::Array{String,1}; mr::Float64 = 0.0403)

    # how many ticker symbols do we have?
    Nₐ = length(ticker_array)
    m = length(data["SPY"][!, :close]) - 1;

    # initialize -
    n = m + 2
    RR = Array{Float64,2}(undef, (Nₐ + 1), m)

    # main loop -
    for i ∈ 1:Nₐ
        
        # grab a data set -
        tmp_ticker = ticker_array[i];
        tmp_data = data[tmp_ticker]
        # 𝒫 = sort(tmp_data, [order(:timestamp, rev=true), :close]);
        𝒫 = tmp_data;
        
        # compute R -
	    for j ∈ 1:m
            RR[i, j] = ((𝒫[n-j,:close] - 𝒫[n-j - 1,:close])/(𝒫[n-j - 1, :close]));
	    end
    end

    # for the last row, add the risk free rate of return -
    for j ∈ 1:m
        RR[end,j] = mr
    end
        
    # return -
    return RR
end

function compute_realized_return(data::DataFrame; mr::Float64 = 0.0403)

    # initialize -
    m = length(data[!, :close]) - 1;

    # initialize -
    n = m + 2
    RR = Array{Float64,2}(undef, 2, m)

    # 𝒫 = sort(data, [order(:timestamp, rev=true), :close]);
    𝒫 = data;
        
    # compute R -
	for j ∈ 1:m
        RR[1, j] = ((𝒫[n-j,:close] - 𝒫[n-j - 1,:close])/(𝒫[n-j - 1, :close]));
	end

    # for the last row, add the risk free rate of return -
    for j ∈ 1:m
        RR[end,j] = mr
    end

    # return -
    return RR;
end

function compute_excess_return(data::DataFrame; m::Int64 = 30, rf::Float64 = 0.0403, λ::Float64 = 0.0)

	# sort the data (newest data on top)
	𝒫 = sort(data, [order(:timestamp, rev=true), :close]);

	# initialize -
	n = m + 2
	R = Array{Float64,1}(undef, m)
    W = Array{Float64,1}(undef, m)
    R̂ = Array{Float64,1}(undef, m)

	# compute R -
	for i ∈ 1:m
		# compute the log return - and capture
        R[i] = ((𝒫[n-i,:close] - 𝒫[n-i - 1,:close])/(𝒫[n-i - 1,:close]) - rf)*100;
        W[i] = exp(-λ*i)
        R̂[i] = W[i]*R[i];
	end

    # compute the partion function -
    Z = sum(W);
    μᵦ = (1/Z)*sum(R̂);
    pᵦ = (1/Z)*W;

	# return -
	return (R, R̂, W, μᵦ, pᵦ)
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

function clean(data::Dict{String, DataFrame})::Dict{String, DataFrame}

    # how many elements do we have in SPY?
    spy_df_length = length(data["SPY"][!,:close]);

    # go through each of the tickers and *remove* tickers that don't have the same length as SPY -
    price_data_dictionary = Dict{String, DataFrame}();
    for (ticker, test_df) ∈ data
    
        # how long is test_df?
        test_df_length = length(test_df[!,:close])
        if (test_df_length == spy_df_length)
        price_data_dictionary[ticker] = test_df; 
        else
            println("Length violation: $(ticker) was removed; dim(SPY) = $(spy_df_length) days and dim($(ticker)) = $(test_df_length) days")
        end
    end

    # return -
    return price_data_dictionary;
end

function partition(data::Dict{String, DataFrame}, stop::Int64)::Tuple{Dict{String, DataFrame}, Dict{String, DataFrame}}

    # initialize *two* pric edata DataFrames -
    training = Dict{String, DataFrame}()
    prediction = Dict{String, DataFrame}();

    # main loop -
    for (ticker, test_df) ∈ data

        # grab the 1:stop index - that is training, the rest is prediction -
        training_df = test_df[1:stop,:];
        prediction_df = test_df[(stop+1):end, :];

        # package -
        training[ticker] = training_df;
        prediction[ticker] = prediction_df;
    end

    return (training, prediction)
end

function build(price_data_dictionary::Dict{String, DataFrame}, ticker_symbol_array::Array{String,1}; 
    m̂::Int64 = 100, rf::Float64 = 0.01, λ̂::Float64 = 0.001)::Dict{String, SingleIndexModel}

    # initialize -
    sim_model_dictionary = Dict{String, SingleIndexModel}();
    risk_free_daily = rf;
    Nₐ = length(ticker_symbol_array);

    # compute the excess nreturn for SPY (which is in the data set)
    (Rₘ, R̂ₘ, W, μᵦ, pᵦ) = compute_excess_return(price_data_dictionary["SPY"]; 
        m = m̂, rf = risk_free_daily, λ = λ̂);

    # main loop -
    for i ∈ 1:Nₐ
    
        # grab a ticker -
        asset_ticker = ticker_symbol_array[i];
        
        # compute the excess return for asset_ticker -
        (Rᵢ, R̂ᵢ, W, μᵦ, pᵦ) = compute_excess_return(price_data_dictionary[asset_ticker]; 
            m = m̂, rf = risk_free_daily, λ = λ̂);
        
        # formulate the Y and X arrays with the price data -
        max_length = length(R̂ᵢ);
        Y = R̂ᵢ;
        X = [ones(max_length) R̂ₘ];
        
        # compute θ -
        θ = inv(transpose(X)*X)*transpose(X)*Y
        
        # package -
        sim_model = SingleIndexModel();
        sim_model.α = θ[1];
        sim_model.β = θ[2];
        sim_model.r = risk_free_daily;
        sim_model_dictionary[asset_ticker] = sim_model;
    end

    # main loop -
    for i ∈ 1:Nₐ
    
        # grab a ticker -
        asset_ticker = ticker_symbol_array[i];
    
        # grab the model -
        sim_model = sim_model_dictionary[asset_ticker];
    
        # compute the excess return for asset_ticker (data) -
        (Rᵢ, R̂ᵢ, W, μᵦ, pᵦ) = compute_excess_return(price_data_dictionary[asset_ticker];  
            m = m̂, rf = risk_free_daily, λ = λ̂);
        
        # compute the model excess return -
        αᵢ = sim_model.α
        βᵢ = sim_model.β
        R_prediction = αᵢ .+ βᵢ .* R̂ₘ
    
        # compute the residual -
        Δ = R̂ᵢ .- R_prediction;
    
        # Esimate a distribution -
        d = fit_mle(Normal, Δ);
    
        # update the sim_model -
        sim_model.ϵ = d;
    end

    # return -
    return sim_model_dictionary;
end

function table(data::Array{Float64,2}, portfolio_index::Int64, Σ_array::Array{Float64, 2}, μ_vector::Array{Float64,1}, ticker_symbol_array::Array{String,1}; 
    δ::Float64 = 0.01)::Array{Any,2}

    # find the indexes of the assets that are "not small" -
    idx_not_small = findall(x-> abs(x) >= δ, data[portfolio_index, 3:end])
    A = length(idx_not_small);

    # setup table -
    allocation_table_data = Array{Any,2}(undef, A+1, 4);
    for a ∈ 1:A
    
        # grab the data -
        idx = idx_not_small[a];
        ticker = ticker_symbol_array[idx]
        ωₐ = data[portfolio_index,(idx .+ 2)];

        # package -
        allocation_table_data[a,1] = ticker;
        allocation_table_data[a,2] = ωₐ
        allocation_table_data[a,3] = μ_vector[idx];
        allocation_table_data[a,4] = Σ_array[idx,idx];
    end

    # add a total row -
    allocation_table_data[end,1] = "Total"
    allocation_table_data[end,2] = sum(data[portfolio_index, (idx_not_small .+ 2)])
    allocation_table_data[end,3] = data[portfolio_index,2];
    allocation_table_data[end,4] = data[portfolio_index,1];

    # return allocation table -
    return allocation_table_data;
end

function index(data::Array{Float64,2}; σ::Float64)::Union{Nothing, Int64}

    # what portfolio index do we need?
    portfolio_index = findall(x->x<=σ, data[:,1])[end]

    # return -
    return portfolio_index
end

function wealth(R::Array{Float64,2}, ω::Array{Float64,1}, Wₒ::Float64)::Array{Float64,1}

    # initialize -
    RRT = transpose(R)
    (Nₜ, Nₐ) = size(RRT);
    WA = Array{Float64,1}(undef, Nₜ);
    WA[1] = Wₒ; # initially we have Wₒ 
    
    # compute the portfolio return -
    RP = RRT*ω

    # main loop - 
    for t ∈ 1:(Nₜ - 1)
        WA[t+1] = WA[t]*(1+RP[t])
    end

    # return -
    return WA
end