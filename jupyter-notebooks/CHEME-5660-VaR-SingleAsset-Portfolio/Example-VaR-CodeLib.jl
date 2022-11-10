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