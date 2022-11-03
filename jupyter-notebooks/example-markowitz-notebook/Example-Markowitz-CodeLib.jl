function compute_minvar_portfolio_allocation(μ,Σ,target_return::Float64; 
    w_lower::Float64 = 0.0, w_upper::Float64 = 1.0)

    # initialize -
    number_of_assets = length(μ)
    w = Variable(number_of_assets)
    risk = quadform(w,Σ)
    ret  = dot(w,μ)

    # setup problem -
    p = minimize(risk)
    p.constraints += [sum(w)==1.0, w_lower <= w, w <= w_upper, ret >= target_return]
    Convex.solve!(p, SCS.Optimizer(); silent_solver = true)

    # return -
    return (p.status, evaluate(w), p.optval, evaluate(ret))
end

function compute_minvar_portfolio_allocation_risk_free(μ,Σ, target_return::Float64, risk_free_return::Float64; 
    w_lower::Float64 = 0.0, w_upper::Float64 = 1.0)

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

# function compute_fractional_return_array(data_table::DataFrame, map::Pair{Symbol,Symbol}; Δt = (1.0 / 365.0))

#     # initialize -
#     (number_of_rows, _) = size(data_table)
#     return_table = DataFrame(timestamp = Date[], P1 = Float64[], P2 = Float64[], μ = Float64[])

#     # main loop -
#     for row_index = 2:number_of_rows

#         # grab the date -
#         tmp_date = data_table[row_index, map.first]

#         # grab the price data -
#         yesterday_close_price = data_table[row_index-1, map.second]
#         today_close_price = data_table[row_index, map.second]

#         # compute the diff -
#         μ  = ((today_close_price - yesterday_close_price) / yesterday_close_price)*100
#         #μ = max(0,tmp)

#         # push! -
#         push!(return_table, (tmp_date, yesterday_close_price, today_close_price, μ))
#     end

#     # return -
#     return return_table
# end


function compute_fractional_return_array(data::DataFrame; m::Int64 = 30, rf::Float64 = 0.0403)::DataFrame

	# sort the data (newest data on top)
	𝒫 = sort(data, [order(:timestamp, rev=true), :close]);
	
	# initialize -
	n = m + 2
	# R = Array{Float64,1}(undef, m)
    return_table = DataFrame(timestamp = Date[], R = Float64[])

	# compute R -
	for i ∈ 1:m

        # grab the date -
        tmp_date = 𝒫[i, :timestamp]

		# compute the log return - and capture
		# R[i] = log(𝒫[n-i,:close]/𝒫[n-i - 1,:close])
        R = ((𝒫[n-i,:close] - 𝒫[n-i - 1,:close])/(𝒫[n-i - 1,:close]) - rf)*100
        
        # push! -
        push!(return_table, (tmp_date, R))
	end

	# return -
	return return_table;
end;

function compute_covariance_array(tickers::Array{String,1}, return_data_dictionary::Dict{String, DataFrame})::Array{Float64,2}

    # how many tickers do we have?
    number_of_tickers = length(tickers)
    Σ = Array{Float64,2}(undef, number_of_tickers, number_of_tickers);
    
    # build a list of Distributions -
    for i = 1:number_of_tickers
        
        # get the ticker -
        outer_ticker = tickers[i];

        # get the return -
        μᵢ = return_data_dictionary[outer_ticker][!,:R]

        # compute the sigma -
        σᵢ = std(μᵢ)

        for j = 1:number_of_tickers
            
            # get the innder ticker -
            inner_ticker = tickers[j];
            
            # get the return -
            μⱼ = return_data_dictionary[inner_ticker][!,:R]
            
            # compute the sigma -
            σⱼ = std(μⱼ)

            # get the lengths -
            outer_length = length(μᵢ)
            inner_length = length(μⱼ)
            compare_length = min(outer_length, inner_length)

            # compute the ρ -
            ρ = cor(μᵢ[1:compare_length], μⱼ[1:compare_length])

            # build -
            if (i == j)
                Σ[i,j] = σᵢ^2
            else
                Σ[i,j] = σᵢ*σⱼ*ρ
            end
        end
    end 
    
    return Σ;
end

function compute_mean_return_array(tickers::Array{String,1}, return_data_dictionary::Dict{String, DataFrame})::Array{Float64,1}

    # how many tickers do we have?
    number_of_tickers = length(tickers)
    μ_vector = Array{Float64,1}(undef, number_of_tickers)

    for i = 1:number_of_tickers
        
        # get the ticker -
        ticker = tickers[i];

        # get the return -
        μᵢ = return_data_dictionary[ticker][!,:R]

        # compute the mean -
        μ_vector[i] = mean(μᵢ)
    end

    return μ_vector;
end