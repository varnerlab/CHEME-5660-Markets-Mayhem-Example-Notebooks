mutable struct QLearningModel

    # data -
    𝒮::Array{Int64,1}
    𝒜::Array{Int64,1}
    Q::Array{Float64,2}
    γ::Float64
    α::Float64

    # constructor -
    QLearningModel() = new();
end

mutable struct TradeBotModel

    # data -
    ticker::String
    policy::Array{Int64,1}
    W::Array{Float64,2}

    # constructor -
    TradeBotModel() = new();
end



# define a lookahead function -
lookahead(model::QLearningModel, s, a) = model.Q[s,a];

# define a update function -
function update!(model::QLearningModel, s, a, r, s′)

    # get stuff from the model -
    γ = model.γ
    α = model.α
    Q = model.Q

    # @show (s, a, r, s′)

    # update -
    Q[s,a] += α*(r + γ*maximum(Q[s′,:]) - Q[s,a])

    # return -
    return model;
end

function state(price::Float64; μ::Float64 = 0.0, σ::Float64 = 1.0, δ::Float64 = 0.1)

    # compute the Z -
    Z = (price - μ)/σ;


    # bin the Z-score -
    if (0.0 <= Z <= δ)
        return 1
    elseif ( Z > δ)
        return 2
    elseif (-δ < Z < 0.0)
        return 3
    elseif (Z <= -δ)
        return 4
    end
end

function price(data::DataFrame,index::Int64)::Float64

    H = data[index,:high];
    L = data[index,:low];
    d = Uniform(0,1);
    θ = rand(d);
    return H*θ + (1-θ)*L
end

function partition(data::Dict{String, DataFrame}; fraction::Float64)::Tuple{Dict{String, DataFrame}, Dict{String, DataFrame}}

    # initialize *two* pric edata DataFrames -
    training = Dict{String, DataFrame}()
    prediction = Dict{String, DataFrame}();

    # main loop -
    for (ticker, test_df) ∈ data

        # how big is this data set -
        Nᵣ = nrow(test_df);
        stop = Int64(round(Nᵣ*fraction))

        # grab the 1:stop index - that is training, the rest is prediction -
        training_df = test_df[1:stop,:];
        prediction_df = test_df[(stop+1):end, :];

        # package -
        training[ticker] = training_df;
        prediction[ticker] = prediction_df;
    end

    return (training, prediction)
end

function compute_average_cost_old(account::DataFrame)::Float64

    # initialize -
    number_of_transactions = nrow(account)
    tmp_array = Array{Float64,2}(undef, number_of_transactions, 2)

    # compute the total number of shares that we have -
    total_number_of_shares = 0.0;
    for i ∈ 1:number_of_transactions
        
        # get the data -
        action_flag = account[i,:action];
        nᵢ = account[i,:Δ]; 
        price = account[i,:price];
        
        # grab the volume and price data for later -
        tmp_array[i,1] = nᵢ;
        tmp_array[i,2] = price;
    
        # sense -
        sense_flag = 1.0
        if (action_flag == 2)
            sense = -1.0
        elseif (action_flag == 3)
            sense = 0.0 
        end

        # compute the total -
        total_number_of_shares = total_number_of_shares + sense_flag*nᵢ; 
    end

    # update the volume to fraction -
    for i ∈ 1:number_of_transactions
        raw_volume = tmp_array[i,1];
        tmp_array[i,1] = (raw_volume/total_number_of_shares);
    end

    # compute the vwap -
    ω = tmp_array[:,1];
    p = tmp_array[:,2];

    # return -
    return sum(ω.*p);
end

function compute_average_cost(account::DataFrame)::Float64
    
    tmp = account;
    cost_array = Array{Float64,1}()
    for i ∈ 1:nrow(tmp)
    
        aᵢ = tmp[i,:action];
        
        if (aᵢ == 1)
            Δ = tmp[i,:Δ];
            p = tmp[i,:price];
            cost = Δ*p;
            push!(cost_array, cost);
        elseif (aᵢ == 2)
            Δ = tmp[i,:Δ];
            p = tmp[i,:price];
            cost = -Δ*p;
            push!(cost_array, cost);
        elseif (aᵢ == 3)
            push!(cost_array, 0.0);
        end
    end

    # compute the total cost -
    total_cost = sum(cost_array)
    number_of_shares = tmp[end, :size];
    avg_cost = (total_cost)/number_of_shares
    return avg_cost;
end

function vwap(ledger::DataFrame)::Float64

    # initialize -
    number_of_transactions = nrow(ledger)
    tmp_array = Array{Float64,2}(undef, number_of_transactions, 2)

    # compute the total number of shares that we have -
    total_number_of_shares = 0.0;
    for i ∈ 1:number_of_transactions
        
        # get the data -
        action_flag = ledger[i,:action];
        nᵢ = ledger[i,:Δ]; 
        price = ledger[i,:price];
        
        # grab the volume and price data for later -
        tmp_array[i,1] = nᵢ;
        tmp_array[i,2] = price;
    
        # sense -
        sense_flag = 1.0
        if (action_flag == 2)
            sense = -1.0
        elseif (action_flag == 3)
            sense = 0.0 
        end

        # compute the total -
        total_number_of_shares = total_number_of_shares + sense_flag*nᵢ; 
    end

    # update the volume to fraction -
    for i ∈ 1:number_of_transactions
        raw_volume = tmp_array[i,1];
        tmp_array[i,1] = (raw_volume/total_number_of_shares);
    end

    # compute the vwap -
    ω = tmp_array[:,1];
    p = tmp_array[:,2];

    # return -
    return sum(ω.*p);
end

function π(Q_array::Array{Float64,2})::Array{Int64,1}

    # get the dimension -
    (NR, NA) = size(Q_array);

    # initialize some storage -
    π_array = Array{Int64,1}(undef, NR)
    for s ∈ 1:NR

        # do a check - if all zeros, then give state of 0 -
        idx_zeros = findall(x->x==0.0, Q_array[s,:]);
        if (length(idx_zeros) == NA)
            π_array[s] = 0;
        else
            π_array[s] = argmax(Q_array[s,:]);
        end
    end

    # return -
    return π_array;
end

function liquidate(ledger::DataFrame, p::Float64)::Float64

    # compute the vwap for this portfolio -
    #vwap_value = vwap(ledger);
    avgcost = compute_average_cost(ledger)
    return (p - avgcost)
end

function compute_position_size(ledger::DataFrame)::Int64

    # initialize -
    current_position_size = 0.0;
    for i ∈ 1:nrow(ledger)
        
        # get action, and the size for this ledger entry -
        aᵢ = ledger[i,:action]
        nᵢ = ledger[i,:Δ];

        if (aᵢ == 1)
            current_position_size = current_position_size + nᵢ
        elseif (aᵢ == 2)
            current_position_size = current_position_size - nᵢ
        end
    end

    return current_position_size;
end

function softmax(data::Array{Float64,1})

    # initialize -
    value_array = Array{Float64,1}();
    

    # compute the demonimator -
    D = sum(exp.(data))

    for value in data
        N = exp(value);
        push!(value_array, N/D)
    end
    
    return value_array;
end

function state(price::Float64, W::Array{Float64,2})::Int64

    # initialize -
    test_class = Array{Float64,1}(undef, 4);

    # compute the score for each class -
    test_class[1] = price*W[1,1]+W[2,1]
    test_class[2] = price*W[1,2]+W[2,2]
    test_class[3] = price*W[1,3]+W[2,3]
    test_class[4] = price*W[1,4]+W[2,4]

    # return the class -
    return argmax(softmax(test_class))
end

function build(model::Type{TradeBotModel}; 
    ticker::String="XYZ", policy::Array{Int64,1} = [1,1,1,1], W::Array{Float64,2} = zeros(1,1))::TradeBotModel

    # build an empty model instance -
    trade_bot_model = TradeBotModel();
    trade_bot_model.policy = policy;
    trade_bot_model.ticker = ticker;
    trade_bot_model.W = W;

    # return -
    return trade_bot_model;
end