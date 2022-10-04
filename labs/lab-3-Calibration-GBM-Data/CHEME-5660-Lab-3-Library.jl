abstract type AbstractSecurityModel end

# types -
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

function E(model::GeometricBrownianMotionModel)::Array{Float64,2}

    # initialize -
    μ = model.μ
    T₁ = model.T₁
    T₂ = model.T₂
    h = model.h
    Xₒ = model.Xₒ

    # setup the time range -
    time_array = range(T₁,stop=T₂, step = h) |> collect
    Nₜ = length(time_array)

    # expectation -
    expectation_array = zeros(Nₜ, 2)

    # main loop -
    for i ∈ 1:Nₜ

        # get the time value -
        t = (time_array[i] - time_array[1])

        # compute the expectation -
        value = Xₒ*exp(μ*t)

        # capture -
        expectation_array[i,1] = t+time_array[1]
        expectation_array[i,2] = value
    end
   

    # return -
    return expectation_array
end

function E(data::DataFrame, key::Symbol)::Array{Float64,2}

    # initialize -
	(NR,_) = size(data)
	expectation_array = zeros(NR,2)

	for i ∈ 1:NR
		idx_range = range(1,stop=i,step=1)
		tmp_array = data[idx_range,key]
		mean_value = mean(tmp_array)
		
        expectation_array[i,1] = i*(1/365) - (1/365)
        expectation_array[i,2] = mean_value
	end

	# return -
	return expectation_array
end

function Var(model::GeometricBrownianMotionModel)::Array{Float64,2}

    # initialize -
    μ = model.μ
    σ = model.σ
    T₁ = model.T₁
    T₂ = model.T₂
    h = model.h
    Xₒ = model.Xₒ

    # setup the time range -
    time_array = range(T₁,stop=T₂, step = h) |> collect
    Nₜ = length(time_array)

    # expectation -
    variance_array = zeros(Nₜ, 2)

    # main loop -
    for i ∈ 1:Nₜ

        # get the time value -
        t = time_array[i] - time_array[1]

        # compute the expectation -
        value = (Xₒ^2)*exp(2*μ*t)*(exp((σ^2)*t) - 1)

        # capture -
        variance_array[i,1] = t + time_array[1]
        variance_array[i,2] = value
    end
   

    # return -
    return variance_array
end

function Var(data::DataFrame, key::Symbol)::Array{Float64,2}

	# initialize -
	(NR,_) = size(data)
	variance_array = zeros(NR,2)

	for i ∈ 1:NR
		idx_range = range(1,stop=i,step=1)
		tmp_array = data[idx_range,key]
		var_value = var(tmp_array; corrected=false)
		
        variance_array[i,1] = i*(1/365) - (1/365)
        variance_array[i,2] = var_value
	end

	# return -
	return variance_array
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