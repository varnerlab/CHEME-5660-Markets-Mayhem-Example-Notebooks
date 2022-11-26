abstract type AbstractSamplingModel end

mutable struct ThompsonSamplingModel <: AbstractSamplingModel

    # data -
    α::Array{Float64,1}
    β::Array{Float64,1}
    K::Int64

    # constructor -
    ThompsonSamplingModel() = new();
end

# placeholder - always return 0
_null(action::Int64)::Int64 = return 0;


# main sampling method -
function sample(model::ThompsonSamplingModel; 𝒯::Int64 = 0, world::Function = _null)::Dict{Int64,Beta}

    # initialize -
    α = model.α
    β = model.β
    K = model.K
    θ̂_vector = Array{Float64,1}(undef, K)

    # initialize collection of Beta distributions -
    action_distribution_dict = Dict{Int64, Beta}();
    for k ∈ 1:K
        action_distribution_dict[k] = Beta(α[k], β[k]);
    end

    # main sampling loop -
    for _ ∈ 1:𝒯
        for k ∈ 1:K

            # grab the distribution for action k -
            d = action_distribution_dict[k];

            # generate a sample for this action -
            θ̂_vector[k] = rand(d);
        end

        # ok: let's choose an action -
        aₜ = argmax(θ̂_vector);

        # pass that action to the world function, gives back a reward -
        rₜ = world(aₜ);

        # update the parameters -
        # first, get the old parameters -
        old_d = action_distribution_dict[aₜ];
        α,β = params(old_d);

        # update the old values with the new values -
        α = α + rₜ
        β = β + (1-rₜ)

        # build new distribution -
        action_distribution_dict[aₜ] = Beta(α, β);
    end
    
    # return -
    return action_distribution_dict;
end 