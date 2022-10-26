function compute_log_return(data::DataFrame; key::Symbol = :close, m::Int64 = 30)::Array{Float64,1}

    # sort the data (newest data on top)
	𝒫 = sort(data, [order(:timestamp, rev=true), key]);
	
	# initialize -
	n = m + 2
	R = Array{Float64,1}(undef,m)

	# compute R -
	for i ∈ 1:m
		# compute the log return - and capture
		R[i] = log(𝒫[n-i,key]/𝒫[n-i - 1,key])
	end

    # return -
    return R
end

function next(d::Laplace, Sₒ::Float64; Δt::Float64 = 1.0)

    # draw a random value from the return distribuion -
    μ = rand(d)

    # draw a value -
    return Sₒ*exp(μ*Δt);
end

function ticker(type::String, underlying::String, expiration::Date, K::Float64)::String

    # build components for the options ticker -
    ticker_component = uppercase(underlying)
    YY = year(expiration) - 2000 # hack to get 2 digit year 
    MM = lpad(month(expiration), 2, "0")
    DD = lpad(day(expiration), 2, "0")

    # compute the price code -
    strike_component = lpad(convert(Int64,K*1000), 8, "0")

    # build the ticker string -
    ticker_string = "O:$(ticker_component)$(YY)$(MM)$(DD)$(type)$(strike_component)"
    
    # return -
    return ticker_string
end

function ticker(type::String, underlying::String, expiration::Date, K::Float64)::String

    # build components for the options ticker -
    ticker_component = uppercase(underlying)
    YY = year(expiration) - 2000 # hack to get 2 digit year 
    MM = lpad(month(expiration), 2, "0")
    DD = lpad(day(expiration), 2, "0")

    # compute the price code -
    strike_component = lpad(convert(Int64,K*1000), 8, "0")

    # build the ticker string -
    ticker_string = "O:$(ticker_component)$(YY)$(MM)$(DD)$(type)$(strike_component)"
    
    # return -
    return ticker_string
end;