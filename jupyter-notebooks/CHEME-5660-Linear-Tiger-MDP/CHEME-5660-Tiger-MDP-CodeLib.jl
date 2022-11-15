rectangle(w, h, x, y) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])

mutable struct MDP

    # data -
    𝒮::Array{Int64,1}
    𝒜::Array{Int64,1}
    T::Array{Float64,3}
    R::Array{Float64,2}
    γ::Float64
    

    # constructor -
    MDP() = new()
end

function build(type::Type{MDP}; 
    𝒮::Array{Int64,1} = Array{Int64,1}(undef,1), 
    𝒜::Array{Int64,1} = Array{Int64,2}(undef,1), 
    T::Array{Float64,3} = Array{Float64,3}(undef,1,1,1), 
    R::Array{Float64,2} = Array{Float64,2}(undef, 1,1), 
    γ::Float64 = 0.1)

    # build and empty MDP -
    m = MDP();

    # add data -
    m.R = R;
    m.T = T;
    m.𝒜 = 𝒜;
    m.𝒮 = 𝒮;
    m.γ = γ

    # return -
    return m;
end

function lookahead(p::MDP, U::Vector{Float64}, s::Int64, a::Int64)

    # grab stuff from the problem -
    R = p.R;  # reward -
    T = p.T;    
    γ = p.γ;
    𝒮 = p.𝒮;
    
    # setup my state array -
    return R[s,a] + γ*sum(T[s,s′,a]*U[i] for (i,s′) in enumerate(𝒮))
end

function iterative_policy_evaluation(p::MDP, π, k_max)

    # grab stuff from the problem -
    R = p.R;  # reward -
    T = p.T;    
    γ = p.γ;
    𝒮 = p.𝒮;

    # initialize value -
    U = [0.0 for s ∈ 𝒮];

    for k ∈ 1:k_max
        U = [lookahead(p, U, s, π(s)) for s ∈ 𝒮]
    end

    return U;
end

function Q(p::MDP, U::Array{Float64,1})::Array{Float64,2}

    # grab stuff from the problem -
    R = p.R;  # reward -
    T = p.T;    
    γ = p.γ;
    𝒮 = p.𝒮;
    𝒜 = p.𝒜

    # initialize -
    Q_array = Array{Float64,2}(undef, length(𝒮), length(𝒜))

    for s ∈ 1:length(𝒮)
        for a ∈ 1:length(𝒜)
            Q_array[s,a] = R[s,a] + γ*sum([T[s,s′,a]*U[s′] for s′ in 𝒮]);
        end
    end

    return Q_array
end

function π(Q_array::Array{Float64,2})::Array{Int64,1}

    # get the dimension -
    (NR, _) = size(Q_array);

    # initialize some storage -
    π_array = Array{Int64,1}(undef, NR)
    for s ∈ 1:NR
        π_array[s] = argmax(Q_array[s,:]);
    end

    # return -
    return π_array;
end