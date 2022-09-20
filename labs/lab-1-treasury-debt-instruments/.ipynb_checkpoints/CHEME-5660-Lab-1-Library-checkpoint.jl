abstract type AbstractTreasuryInstrument end

# types -
mutable struct MultipleCouponBondModel <: AbstractTreasuryInstrument

    # data -
    Vₚ::Float64
    T::Float64
    c̄::Float64
    r̄::Float64
    λ::Float64

    # constructor -
    MultipleCouponBondModel() = new()
end

mutable struct ZeroCouponBillModel <: AbstractTreasuryInstrument

    # data -
    Vₚ::Float64
    T::Float64
    r̄::Float64
    λ::Float64

    # constructor -
    ZeroCouponBillModel() = new()    
end


# ------------------------------------------------------------------------------------------- #
# price: Computes the fair price of a zero-coupon T-bill/note/bond
#
# Args:
# Vₚ::Float64 				Par value of T-bill/note/bond (units: USD future)
# T::Union{Float64,Int54} 	Term of the T-bill/note/bond 	(units: years)
# r̄::Float64 				Market interest rate (decimal)
#
# Outputs:
# Vᵦ::Float64 				Fair price of the T-bill/note/bond (units: USD current)
# ------------------------------------------------------------------------------------------- #
function price(Vₚ::Float64, T::Float64, r̄::Float64; λ::Float64 = 1.0)::Float64

	# initialize -
	Vᵦ = 0.0
    i = (r̄/λ)
    N = λ*T

	# compute the discount factor -
	𝒟 = (1/((1+i)^(N)))

	# compute the current price -
	Vᵦ = 𝒟*Vₚ
	
	# return -
	return Vᵦ
end;

function price(Vₚ::Float64, T::Float64, c̄::Float64, r̄::Float64; λ::Float64 = 2.0)::Float64

    # initialize -
	i = (r̄/λ)
	C = (c̄/λ)*Vₚ
	N = λ*T # two payments per year -
	
	# compute the final payout -
	final_payout = Vₚ/((1+i)^(N)) # pay out the par value -
	coupon_payments = Array{Float64,1}()
	
	# main loop -
	for j ∈ 1:N

		# compute the present value of future coupon payments in year t -
		value = C/((1+i)^(j))

		# capture -
		push!(coupon_payments, value)
	end

	# compute the Vᵦ -
	return (final_payout+sum(coupon_payments))
end;


# Easy versions of the price methods -
function price(model::MultipleCouponBondModel)::Float64

    # get parameters from the model -
    Vₚ = model.Vₚ
    T = model.T
    c̄ = model.c̄
    r̄ = model.r̄
    λ = model.λ

    # compute -
    return price(Vₚ, T, c̄, r̄; λ = λ)
end

function price(model::ZeroCouponBillModel)::Float64

    # get parameters from the model -
    Vₚ = model.Vₚ
    T = model.T
    r̄ = model.r̄
    λ = model.λ

    # return -
    return price(Vₚ, T, r̄; λ = λ);
end