
# build a transaction type -
mutable struct TransactionModel

    # data -
    volume::Int64
    price::Float64
    sense::Int64

    # constructor -
    TransactionModel() = new();
end

function build(type::Type{TransactionModel}; 
    volume::Float64 = 0.0, price::Float64 = 0.0, sense::Int64 = 1)

    # build blank transaction model -
    model = TransactionModel();
    model.volume = volume;
    model.price = price;
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

function initialize(data::DataFrame; lotsize::Float64 = 1.0, periods::Int64=1)

    # initialize -
    tmp_array = Array{Any,2}(undef, periods, 4)

    # compute a parameter to simulate friction -
    d = Uniform(0,1);

    # main loop -
    for i ∈ 1:periods
        
        # compute rand value -
        θ = rand(d);

        # get the high low for this period -
        H = data[i,:high]
        L = data[i,:low]
        time = data[i,:timestamp]

        # get the open -
        tmp_array[i,1] = lotsize;
        tmp_array[i,2] = 1.0;
        tmp_array[i,3] = θ*H + (1-θ)*L
        tmp_array[i,4] = time;
    end

    # # compute the average share price -
    # n_total = sum(tmp_array[:,1]);
    # for i ∈ 1:periods
    #     tmp_array[i,2] = (tmp_array[i,1]/n_total);
    # end

    # ω = tmp_array[:,2]
    # p = tmp_array[:,3]
    # avg_price = sum(ω.*p)
    
    return tmp_array
end

function compute_aggregate_price(trades::Dict{Int64, Pair{Float64,Float64}})::Float64

    # initialize -
    number_of_trades = length(trades);
    total_position_size = 0.0;
    aggregate_price = 0.0;

    for (d,trade) ∈ trades
        total_position_size = total_position_size + trade.first
    end
    
    # return -
    return total_position_size;
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
        price = data.price;
        
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
    price_value = 0.0;
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