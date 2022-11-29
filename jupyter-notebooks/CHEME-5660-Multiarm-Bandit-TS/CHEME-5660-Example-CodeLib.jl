abstract type AbstractSamplingModel end

mutable struct ThompsonSamplingModel <: AbstractSamplingModel

    # data -
    α::Array{Float64,1}
    β::Array{Float64,1}
    K::Int64

    # constructor -
    ThompsonSamplingModel() = new();
end

mutable struct EpsilonSamplingModel <: AbstractSamplingModel

    # data -
    α::Array{Float64,1}
    β::Array{Float64,1}
    K::Int64
    ϵ::Float64

    # constructor -
    EpsilonSamplingModel() = new();
end

# placeholder - always return 0
_null(action::Int64)::Int64 = return 0;


function sample(model::EpsilonSamplingModel, data::Dict{String,DataFrame}, tickers::Array{String,1}; 𝒯::Int64 = 0)

    # initialize -
    α = model.α
    β = model.β
    K = model.K
    ϵ = model.ϵ
    θ̂_vector = Array{Float64,1}(undef, K)
    time_sample_results_dict_Ts = Dict{Int64, Array{Float64,2}}();

    # generate random Categorical distribution -
    parray = [1/K for i = 1:K]
    dcat = Categorical(parray);
    
    # initialize collection of Beta distributions -
    action_distribution = Array{Beta,1}(undef, K);
    for k ∈ 1:K
        action_distribution[k] = Beta(α[k], β[k]); # initialize uniform
    end
 
    # main sampling loop -
    for t ∈ 1:𝒯

        # create a new parameter array -
        parameter_array = Array{Float64,2}(undef, K,2);
        fill!(parameter_array,0.0);

        for k ∈ 1:K
            
            # grab the distribution for action k -
            d = action_distribution[k];

            # store the parameter array -
            αₖ, βₖ = params(d);
            parameter_array[k,1] = αₖ
            parameter_array[k,2] = βₖ

            # store -
            time_sample_results_dict_Ts[t] = parameter_array;
        end

        aₜ = 1; # default to 1
        if (rand() < ϵ)
            aₜ = rand(dcat);
        else
            
            for k ∈ 1:K

                # grab the distribution for action k -
                d = action_distribution[k];
    
                # generate a sample for this action -
                θ̂_vector[k] = rand(d);
            end

            # ok: let's choose an action -
            aₜ = argmax(θ̂_vector);

            # pass that action to the world function, gives back a reward -
            rₜ = world(aₜ, t, data, tickers);

            # update the parameters -
            # first, get the old parameters -
            old_d = action_distribution[aₜ];
            αₒ,βₒ = params(old_d);

            # update the old values with the new values -
            αₜ = αₒ + rₜ
            βₜ = βₒ + (1-rₜ)

            # build new distribution -
            action_distribution[aₜ] = Beta(αₜ, βₜ);
        end
    end

    return time_sample_results_dict_Ts;
end

function sample(model::EpsilonSamplingModel;  𝒯::Int64 = 0, world::Function = _null)::Dict{Int64, Array{Float64,2}}

    # initialize -
    α = model.α
    β = model.β
    K = model.K
    ϵ = model.ϵ
    θ̂_vector = Array{Float64,1}(undef, K)
    time_sample_results_dict = Dict{Int64, Array{Float64,2}}();

    # generate random Categorical distribution -
    parray = [1/K for i = 1:K]
    dcat = Categorical(parray);

    # initialize collection of Beta distributions -
    action_distribution = Array{Beta,1}(undef, K);
    for k ∈ 1:K
        action_distribution[k] = Beta(α[k], β[k]); # initialize uniform
    end

    # main sampling loop -
    for t ∈ 1:𝒯
    
        # create a new parameter array -
        parameter_array = Array{Float64,2}(undef, K,2);
        fill!(parameter_array,0.0);
        
        for k ∈ 1:K
            
            # grab the distribution for action k -
            d = action_distribution[k];

            # store the parameter array -
            αₖ, βₖ = params(d);
            parameter_array[k,1] = αₖ
            parameter_array[k,2] = βₖ

            # store -
            time_sample_results_dict[t] = parameter_array;
        end


        aₜ = 1; # default to 1
        if (rand() < ϵ)
            aₜ = rand(dcat);
        else

            for k ∈ 1:K

                # grab the distribution for action k -
                d = action_distribution[k];
    
                # generate a sample for this action -
                θ̂_vector[k] = rand(d);
            end

            # ok: let's choose an action -
            aₜ = argmax(θ̂_vector);
        end

        # pass that action to the world function, gives back a reward -
        rₜ = world(aₜ);

        # update the parameters -
        # first, get the old parameters -
        old_d = action_distribution[aₜ];
        α,β = params(old_d);

        # update the old values with the new values -
        α = α + rₜ
        β = β + (1-rₜ)

        # build new distribution -
        action_distribution[aₜ] = Beta(α, β);
    end

    # return -
    return time_sample_results_dict;
end

function world(action::Int64, time::Int64, data::Dict{String,DataFrame}, tickers::Array{String,1})::Int64

    # initialize -
    result_flag = 0;

    # daily risk free rate -
    r̄ = 0.0403;
    risk_free_daily = ((1+r̄)^(1/365) - 1);

    # grab the ticker we are looking at?
    ticker_symbol = tickers[action];

    # grab the price -
    price_df = data[ticker_symbol];
    P₁ = price_df[time, :volume_weighted_average_price]
    P₂ = price_df[time + 1, :volume_weighted_average_price]
    R = log(P₂/P₁);
    if (R >= risk_free_daily)
        result_flag = 1;
    end

    # default -
    return result_flag;
end

function sample(model::ThompsonSamplingModel, data::Dict{String,DataFrame}, tickers::Array{String,1}; 
    𝒯::Int64 = 0)::Dict{Int64, Array{Float64,2}}

    # initialize -
    α = model.α
    β = model.β
    K = model.K
    θ̂_vector = Array{Float64,1}(undef, K)
    time_sample_results_dict_Ts = Dict{Int64, Array{Float64,2}}();
 
    # initialize collection of Beta distributions -
    action_distribution = Array{Beta,1}(undef, K);
    for k ∈ 1:K
        action_distribution[k] = Beta(α[k], β[k]); # initialize uniform
    end

    # main sampling loop -
    for t ∈ 1:𝒯

        # create a new parameter array -
        parameter_array = Array{Float64,2}(undef, K,2);
        fill!(parameter_array,0.0);

        for k ∈ 1:K

            # grab the distribution for action k -
            d = action_distribution[k];

            # generate a sample for this action -
            θ̂_vector[k] = rand(d);

            # store the parameter array -
            αₖ, βₖ = params(d);
            parameter_array[k,1] = αₖ
            parameter_array[k,2] = βₖ

            # store -
            time_sample_results_dict_Ts[t] = parameter_array;
        end

        # ok: let's choose an action -
        aₜ = argmax(θ̂_vector);

        # pass that action to the world function, gives back a reward -
        rₜ = world(aₜ, t, data, tickers);

        # update the parameters -
        # first, get the old parameters -
        old_d = action_distribution[aₜ];
        αₒ,βₒ = params(old_d);

        # update the old values with the new values -
        αₜ = αₒ + rₜ
        βₜ = βₒ + (1-rₜ)

        # build new distribution -
        action_distribution[aₜ] = Beta(αₜ, βₜ);
    end
     
    # return -
    return time_sample_results_dict_Ts;
end

# main sampling method -
function sample(model::ThompsonSamplingModel; 𝒯::Int64 = 0, world::Function = _null)::Dict{Int64, Array{Float64,2}}

    # initialize -
    α = model.α
    β = model.β
    K = model.K
    θ̂_vector = Array{Float64,1}(undef, K)
    time_sample_results_dict = Dict{Int64, Array{Float64,2}}();

    # initialize collection of Beta distributions -
    action_distribution = Array{Beta,1}(undef, K);
    for k ∈ 1:K
        action_distribution[k] = Beta(α[k], β[k]); # initialize uniform
    end

    # main sampling loop -
    for t ∈ 1:𝒯

        # create a new parameter array -
        parameter_array = Array{Float64,2}(undef, K,2);
        fill!(parameter_array,0.0);

        for k ∈ 1:K

            # grab the distribution for action k -
            d = action_distribution[k];

            # generate a sample for this action -
            θ̂_vector[k] = rand(d);

            # store the parameter array -
            αₖ, βₖ = params(d);
            parameter_array[k,1] = αₖ
            parameter_array[k,2] = βₖ

            # store -
            time_sample_results_dict[t] = parameter_array;
        end

        # ok: let's choose an action -
        aₜ = argmax(θ̂_vector);

        # pass that action to the world function, gives back a reward -
        rₜ = world(aₜ);

        # update the parameters -
        # first, get the old parameters -
        old_d = action_distribution[aₜ];
        αₒ,βₒ = params(old_d);

        # update the old values with the new values -
        αₜ = αₒ + rₜ
        βₜ = βₒ + (1-rₜ)

        # build new distribution -
        action_distribution[aₜ] = Beta(αₜ, βₜ);
    end
    
    # return -
    return time_sample_results_dict;
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

function build_beta_array(parameters::Array{Float64,2})::Array{Beta,1}

    # build an array of beta distributions -
    (NR,_) = size(parameters);
    beta_array = Array{Beta,1}(undef,NR)
    for i ∈ 1:NR
        
        # grab the parameters -
        α = parameters[i,1];
        β = parameters[i,2];

        # build -
        beta_array[i] = Beta(α, β);
    end

    # return -
    return beta_array;
end

function preference(beta::Array{Beta,1}, tickers::Array{String,1}; N::Int64 = 100)

    # sample -
    K = length(tickers);
    tmp_array = Array{Int64,1}(undef, N);
    θ̂_vector = Array{Float64,1}(undef, K)
    pref_array = Array{Float64,1}(undef, K)

    for i ∈ 1:N
        for k ∈ 1:K
            
            # grab -
            d = beta[k];
            
            # generate a sample for this action -
            θ̂_vector[k] = rand(d);
        end

        # ok: let's choose an action -
        tmp_array[i] = argmax(θ̂_vector);
    end


    # how many of each do we have?
    for k ∈ 1:K
        idx = findall(x->x==k, tmp_array);
        pref_array[k] = length(idx)/N;
    end

    # return -
    pref_array
end
