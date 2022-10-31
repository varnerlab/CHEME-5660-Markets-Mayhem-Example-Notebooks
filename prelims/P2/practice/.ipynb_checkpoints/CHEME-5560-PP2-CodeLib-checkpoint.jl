abstract type AbstractSecurityModel end

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