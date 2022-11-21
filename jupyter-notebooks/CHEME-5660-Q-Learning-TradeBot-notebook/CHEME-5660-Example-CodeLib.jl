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



# define a lookahead function -
lookahead(model::QLearningModel, s, a) = model.Q[s,a];

# define a update function -
function update!(model::QLearningModel, s, a, r, s′)

    # get stuff from the model -
    γ = model.γ
    α = model.α
    Q = model.Q

    # update -
    Q[s,a] += α*(r + γ*maximum(Q[s′,:]) - Q[s,a])

    # return -
    return model;
end

function state(price::Float64; μ::Float64 = 0.0, σ::Float64 = 1.0, ϵ::Float64 = 0.1)

    # compute the Z -
    Z = (price - μ)/σ;

    # bin the Z-score -
    if (0 <= Z <=ϵ)
        return 1
    elseif (Z>ϵ)
        return 2
    elseif (-ϵ<=Z<0)
        return 3
    elseif (Z<-ϵ)
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

function vwap(ledger::DataFrame)::Float64

    # initialize -
    number_of_transactions = nrow(ledger)
    tmp_array = Array{Float64,2}(undef, number_of_transactions, 2)

    # compute the total number of shares that we have -
    total_number_of_shares = 0.0;
    for i ∈ 1:number_of_transactions
        
        # get the data -
        action_flag = ledger[i,:action];
        nᵢ = ledger[i,:n]; 
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
    vwap_value = vwap(ledger);
    return (p - vwap_value)
end