# build a transaction type -
mutable struct TransactionModel

    # data -
    volume::Int64
    p₁::Float64
    p₂::Float64
    sense::Int64
    
    # constructor -
    TransactionModel() = new();
end

function build(type::Type{TransactionModel}; 
    volume::Float64 = 0.0, p₁::Float64 = 0.0, p₂::Float64 = 0.0, sense::Int64 = 1)

    # build blank transaction model -
    model = TransactionModel();
    model.volume = volume;
    model.p₁ = p₁;
    model.p₂ = p₂;
    model.sense = sense;

    # rerturn -
    return model;
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

function initialize(data::DataFrame; lotsize::Float64 = 1.0, start::Int64=1, stop::Int64=1)

    # initialize -
    data_range_array = range(start, stop=stop, step=1) |> collect
    periods = length(data_range_array);

    # init some space -
    tmp_array = Array{Any,2}(undef, periods, 4)
    ledger = Dict{DateTime,TransactionModel}();

    # compute a parameter to simulate friction -
    d = Uniform(0,1);

    # main loop -
    for i ∈ 1:periods
        
        # compute rand value -
        θ = rand(d);

        # what index -
        index = data_range_array[i]

        # get the high low for this period -
        H = data[index,:high]
        L = data[index,:low]
        time = data[index,:timestamp]

        # get the open -
        tmp_array[i,1] = lotsize;
        tmp_array[i,2] = 1.0;
        tmp_array[i,3] = θ*H + (1-θ)*L
        tmp_array[i,4] = time;
    end

    # load these transactions into my trade-ledger 
    (NR,NC) = size(tmp_array);
    for i ∈ 1:NR
    
        # get the time stamp of the trade -
        time = tmp_array[i,4];
    
        # build transaction object -
        ledger[time] = build(TransactionModel, volume=tmp_array[i,1], p₁=tmp_array[i,3], p₂=tmp_array[i,3], sense = 1);
    end
    
    # retur the ledger -
    return ledger
end

function vwap(ledger::Dict{DateTime,TransactionModel})::Float64

    # initialize -
    number_of_transactions = length(ledger)
    tmp_array = Array{Float64,2}(undef,number_of_transactions, 2)

    # get the keys -
    timestamp_array = keys(ledger) |> collect;

    # compute the total number of shares that we have -
    total_number_of_shares = 0.0;
    for i ∈ 1:number_of_transactions
        
        # get the timestamp -
        timestamp = timestamp_array[i];

        # get the data -
        data = ledger[timestamp];
        sense_flag = data.sense;
        volume = data.volume;
        price = data.p₁;
        
        # grab the volume and price data for later -
        tmp_array[i,1] = volume;
        tmp_array[i,2] = price;
    
        # if we are selling, then don't includ in the vwap calculation -
        if (sense_flag == -1)
            tmp_array[i,1] = 0.0;    
        end

        # compute the total -
        total_number_of_shares = total_number_of_shares + sense_flag*volume; 
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

function confirm(ledger::Dict{DateTime,TransactionModel}, trade::TransactionModel)::Bool

    # initialize -
    trade_is_ok_flag = false;
    total_position_size = 0.0;

    # how many shares do we have?
    for (d,model) ∈ ledger
        
        # get the sense and the volume -
        s = model.sense
        volume = model.volume
        Δ = s*volume

        # this is my current total position size 
        total_position_size = total_position_size + Δ;
    end

    # we can't get negative -
    s = trade.sense;
    v = trade.volume;
    if ((total_position_size+s*v) >= 0)
        trade_is_ok_flag = true 
    end

    # return -
    return trade_is_ok_flag
end

function price(data::DataFrame, timestamp::DateTime)::Float64

    # initialize -
    d = Uniform(0,1);

    # get the high/low prices at this timestamp -
    H = filter(:timestamp=>x->x==timestamp,data)[1,:high]
    L = filter(:timestamp=>x->x==timestamp,data)[1,:low]

    # compute a distance betwee these -
    θ = rand(d);

    # return the price -
    return H*θ + (1-θ)*L
end

function compute_price_return(S::Float64, S̄::Float64)::Float64
    return log(S/S̄);
end

function results(episodes::Array{Dict{DateTime,TransactionModel},1}, distribution::Normal; 
    initperiod::Int64=12)

    # initialize -
    df = DataFrame(
        s = Int64[],
        s′ = Int64[],
        a = Int64[],
        r = Float64[]
    );

    # ok, so this is going to get weird ...
    number_of_episodes = length(episodes);
    for i ∈ 1:number_of_episodes
        
        # grab -
        full_run_data_table = episodes[i];

        # get the keys -
        timestamp_array = sort(keys(full_run_data_table) |> collect)

        # ok, we "warmed up" for initperiod -
        warmup_timestamp_array = timestamp_array[1:initperiod];
        warmup_ledger = extract(full_run_data_table; timerange = warmup_timestamp_array);
        initial_vwap_price_value = vwap(warmup_ledger);

        # grab the run -
        run_timestamp_array = timestamp_array[(initperiod+1):end];
        run_ledgers = extract(full_run_data_table; timerange = run_timestamp_array);

        # hack: 
        local_container = Array{Dict{DateTime,TransactionModel},1}();

        # build array -
        number_of_run_steps = length(run_timestamp_array);
        for j ∈ 1:number_of_run_steps
            
            ts = run_timestamp_array[j]
            trade = run_ledgers[ts];
            â = trade.sense;

            # get price -
            p₁ = trade.p₁
            p₂ = trade.p₂

            s = state(distribution, p₁);
            s′ = state(distribution, p₂);

            # compute the return -
            Δ = log(p₂/initial_vwap_price_value)*100;
            r̂ = 1.0;
            if (Δ > 0 && â!=0)
                r̂ = -1;
            end

            # create a results_tuple -
            result_tuple = (
                s = s,
                s′ = s′,
                a = trade.sense,
                r = r̂
            );

            push!(df, result_tuple)
        end
    end

    # return -
    return df;
end

function extract(data::Dict{DateTime,TransactionModel}; timerange::Array{DateTime,1})

    # initialize -
    ledger = Dict{DateTime,TransactionModel}();

    # extract -
    for d ∈ timerange
        ledger[d] = data[d];
    end

    # return -
    return ledger;
end

function state(d::Normal, price::Float64)::Int64

    # initialize -
    state_flag = 0;

    # get parameters from d -
    θ = params(d)

    # compute the Z -
    Z = (price - θ[1])/(θ[2]);

    if (Z>=-0.1 && Z<=0.1)
        state_flag = 1;
    elseif (Z>0.1)
        state_flag = 3;
    elseif (Z<-0.1)
        state_flag = 2;
    end

    # return -
    return state_flag;
end

function reformat(data::DataFrame)

    # initialize -
    𝒮 = [1,2,3];
    𝒜 = [-1,0,1];

    # build Q array -
    Q_array = Array{Float64,2}(undef, length(𝒮), length(𝒜))

    for s ∈ 1:length(𝒮)
        for a ∈ 1:length(𝒜)
            
            # ok, so get all the rewards for this state -
            rewards_vector = filter([:s,:a]=>(x,y)->(x==s && y==𝒜[a]), data)[:,:r];
            
            @show (s, a,  rewards_vector)

        end
    end

    return Q_array;
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
