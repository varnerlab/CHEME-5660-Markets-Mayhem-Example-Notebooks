abstract type AbstractSecurityModel end
abstract type AbstractInterestRateModel end

mutable struct GeometricBrownianMotionModel <: AbstractSecurityModel

    # data -
    μ::Float64
    σ::Float64
    T₁::Float64
    T₂::Float64
    h::Float64
    Xₒ::Float64

    # constructor -
    GeometricBrownianMotionModel() = new()
end

mutable struct CIRModel <: AbstractInterestRateModel

    # data -
    θ::Float64
    α::Float64
    σ::Float64
    T₁::Float64
    T₂::Float64
    h::Float64
    rₒ::Float64

    # constructor -
    CIRModel() = new()
end

function solve(model::GeometricBrownianMotionModel; 𝒫::Int64=100)::Array{Float64,2}

    # initialize -
    μ = model.μ
    σ = model.σ
    T₁ = model.T₁
    T₂ = model.T₂
    h = model.h
    Xₒ = model.Xₒ

	# initialize -
	time_array = range(T₁, stop=T₂, step=h) |> collect
	number_of_time_steps = length(time_array)
	soln_array = zeros(number_of_time_steps, 𝒫+1) # extra column for time -

    # put the time in the first col -
    for t ∈ 1:number_of_time_steps
        soln_array[t,1] = time_array[t]
    end

	# replace first-row w/Xₒ -
	for p ∈ 1:𝒫
		soln_array[1,p+1] = Xₒ
	end

	# build a noise array of Z(0,1)
	d = Normal(0,1)
	ZM = rand(d,number_of_time_steps,𝒫);

	# main simulation loop -
	for p ∈ 1:𝒫
		for t ∈ 1:number_of_time_steps-1
			soln_array[t+1,p+1] = soln_array[t,p+1]*exp((μ - σ^2/2)*h + σ*(sqrt(h))*ZM[t,p])
		end
	end

	# return -
	return soln_array
end

function solve(model::CIRModel; 𝒫::Int64=100)::Array{Float64,2}

    # get parameters from model -
    θ = model.θ
    α = model.α
    σ = model.σ
    T₁ = model.T₁
    T₂ = model.T₂
    h = model.h
    rₒ = model.rₒ

    # initialize -
	time_array = range(T₁, stop=T₂, step=h) |> collect
	number_of_time_steps = length(time_array)
	soln_array = zeros(number_of_time_steps, 𝒫+1) # extra column for time -

    # put the time in the first col -
    for t ∈ 1:number_of_time_steps
        soln_array[t,1] = time_array[t]
    end

	# replace first-row w/Xₒ -
	for p ∈ 1:𝒫
		soln_array[1,p+1] = rₒ
	end

    # build a noise array of Z(0,1)
	d = Normal(0,1)
	ZM = rand(d,number_of_time_steps,𝒫);

	# main simulation loop -
	for p ∈ 1:𝒫
		for t ∈ 1:number_of_time_steps-1

            rₜ = soln_array[t,p+1]
            W = ZM[t,p];
			soln_array[t+1,p+1] = rₜ + (θ-α*rₜ)*h + (sqrt(rₜ*h))*σ*W
		end
	end

	# return -
	return soln_array
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

function P(samples::Array{Float64,1}, value::Float64)::Float64

    # initialize -
    N = length(samples)

    # index vector x leq value -
    idx_vector = findall(x->x<=value, samples);

    # return -
    return (length(idx_vector)/N);
end