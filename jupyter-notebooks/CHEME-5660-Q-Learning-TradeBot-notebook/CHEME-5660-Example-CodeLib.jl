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

function initialize_position(data::DataFrame; lotsize::Float64 = 1.0, days::Int64=1)

    # initialize -
    tmp_array = Array{Float64,2}(undef, days, 3)

    # main loop -
    for i ∈ 1:days
        
        # get the open -
        open_price = data[i,:open]
        tmp_array[i,1] = lotsize;
        tmp_array[i,2] = 0.0;
        tmp_array[i,3] = open_price;
    end

    # compute the average share price -
    n_total = sum(tmp_array[:,1]);
    for i ∈ 1:days
        tmp_array[i,2] = (tmp_array[i,1]/n_total);
    end

    ω = tmp_array[:,2]
    p = tmp_array[:,3]
    avg_price = sum(ω.*p)
    
    return (avg_price, n_total)
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

function confirm(trades::Dict{Int64, Pair{Float64,Float64}}, proposedtrade::Pair{Float64,Float64})::Bool

    # initialize -
    trade_is_ok_flag = false;
    total_position_size = 0.0;

    # how many shares do we have?
    for (d,trade) ∈ trades
        total_position_size = total_position_size + trade.first
    end

    # we can't get negative -
    N = proposedtrade.first
    if ((total_position_size+N) >= 0)
        trade_is_ok_flag = true 
    end

    # @show (total_position_size, N, trade_is_ok_flag)

    # return -
    return trade_is_ok_flag
end

function compute_price_return(S::Float64, S̄::Float64)::Float64
    return log(S/S̄);
end