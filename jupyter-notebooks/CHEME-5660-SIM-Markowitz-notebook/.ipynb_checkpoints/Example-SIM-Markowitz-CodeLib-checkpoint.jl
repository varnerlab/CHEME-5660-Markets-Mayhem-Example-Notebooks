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
        tmp = ((today_close_price - yesterday_close_price) / yesterday_close_price)*100
        μ = max(0,tmp)
        R = μ - rf

        # push! -
        push!(return_table, (tmp_date, μ, R))
    end

    # return -
    return return_table
end