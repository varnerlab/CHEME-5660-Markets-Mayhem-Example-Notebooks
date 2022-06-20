### A Pluto.jl notebook ###
# v0.19.5

using Markdown
using InteractiveUtils

# ╔═╡ c5e35f69-9aed-4d22-b7a4-ba12c049b7d4
# Setup the Julia environment -
begin
	
	# Load Julia packages -
	using DataFrames
	using CSV
	using Statistics
	using JLD2
	using FileIO
	using PlutoUI
	using PrettyTables
	
	# setup paths -
	const _PATH_TO_DIR = joinpath(pwd(), "data")

	# show -
	nothing
end

# ╔═╡ 76cdf8bd-41ec-44f6-ae7b-2dd1e1d61912
md"""
## Engineering Portfolio Variance for Binary and Multicomponent Portfolios
Jeffrey D. Varner, Smith School of Chemical and Biomolecular Engineering, Cornell University, Ithaca NY 14850
"""

# ╔═╡ 68801e9b-1e17-4b85-b39c-352d709bc0c6
md"""
### Introduction
"""

# ╔═╡ 8ebe17b6-a45d-4e05-9324-7fa13a871a51
md"""
### Materials and Methods
"""

# ╔═╡ 8d8de465-04d5-4303-bdcf-cbed2f5a99e3
# ----------------------------------------------------------------------------------------------- #
# Fill me in
# ----------------------------------------------------------------------------------------------- #
function compute_return_array(data::DataFrame; m::Int64 = 30)::Array{Float64,1}

	# sort the data (newest data on top)
	𝒟 = sort(data, [order(:timestamp, rev=true), :close]);

	# how many steps do we want to use?
	n = m + 2
	RA = Array{Float64,1}(undef, m)

	# compute R -
	for i ∈ 1:m
		# compute the log return - and capture
		RA[i] = log(𝒟[n-i,:close]/𝒟[n-i- 1,:close])
	end

	# retrurn -
	return RA
end

# ╔═╡ f465ad78-0ab6-4b1b-addb-b55d3825ff8f
# ----------------------------------------------------------------------------------------------- #
# Fill me in
# ----------------------------------------------------------------------------------------------- #
function compute_binary_portfolio_variance(i::Int64, j::Int64, w₁::Float64, correlation::Array{Float64,2}, 
	sigma::Array{Float64,1})::Float64

	# setup -
	w₂ = 1 - w₁
	σ₁ = sigma[i]
	σ₂ = sigma[j]
	ρ_ij = correlation[i,j]
	σₚ = (w₁^2)*(σ₁^2)+(w₂^2)*(σ₂^2)+2*(w₁*w₂*σ₁*σ₂)*ρ_ij
	
	# return -
	return σₚ
end

# ╔═╡ 252f4d58-1689-44aa-87ad-aa2afe4e7cd6
md"""
### Results and Discussion
"""

# ╔═╡ ff8e88eb-2602-42a2-bde9-ffa78ee49cef
md"""
##### Load the close price dataset:
Daily close prices for $\vert\mathcal{P}\vert$ (semi) random tickers for 06/20/2020 to 06/20/2022
"""

# ╔═╡ 9b5fd848-f020-4082-935c-ab04fc78fc70
begin
	
	# load the data from disk -
	data_dictionary = load(joinpath(_PATH_TO_DIR,"Portfolio-Data-06-20-22.jld2"))["dd"]

	# show -
	nothing
end

# ╔═╡ 52eaa09b-c529-4585-9d73-494253b1fb81
md"""
##### Compute the array of return values:
"""

# ╔═╡ 7e6fc914-bd13-47c2-9278-78ea51f646ff
begin
	
	# assemble the return array R
	# R: m x 𝒫 array holding return values -

	# first: get the "keys" from the data dictionary, and sort them (so we have a known order) -
	ticker_array = sort(collect(keys(data_dictionary)))

	# next: initialize some storage -
	𝒫 = length(ticker_array) # how many tickers do we have in the portfolio?
	m = 45 # number of days to compute the return from -
	R = Array{Float64,2}(undef, m, 𝒫)

	# finally: compute the return array (rows = time, cols = tickers)
	for (i,ticker) ∈ enumerate(ticker_array)
		r = compute_return_array(data_dictionary[ticker]; m = m)
		for k ∈ 1:m
			R[k,i] = r[k]
		end
	end
end

# ╔═╡ e814c126-3c01-461b-8093-b5364865390e
# mean return -
μᵣ = mean(R, dims=1)

# ╔═╡ 63d98244-059b-4784-bd1e-c6e07275c61c
ticker_array

# ╔═╡ d430a0c0-42a8-407c-9cf9-687781152592
# compute the standard deviation array -
σ = reshape(std(R, dims=1), (𝒫)); # compute the standard deviation of the return over the last m days

# ╔═╡ 0880e290-8a05-4efc-b605-27154ec086ea
# compute the correlation array -
ρ = cor(R)

# ╔═╡ 9d0d18be-dcfa-489a-ad78-ff132740ec6d
begin

	# fix: we always want APPL -
	w = 0.50 # assume equal weights -
	varray = Float64[]
	for j ∈ 1:𝒫
		variance = compute_binary_portfolio_variance(1,j,w,ρ,σ)
		push!(varray,variance)
	end
end

# ╔═╡ 8f36a68d-79ed-4b27-9fe8-e7ef9b411e6c
with_terminal() do

	data_table = Array{Any,2}(undef, 𝒫, 6)
	for i ∈ 1:𝒫
		data_table[i,1] = ticker_array[i]
		data_table[i,2] = (w*μᵣ[1] + (1-w)*μᵣ[i])/(μᵣ[1])
		data_table[i,3] = varray[i]/varray[1]
		data_table[i,4] = μᵣ[i]/μᵣ[1]
		data_table[i,5] = σ[i]/σ[1]
		data_table[i,6] = ρ[1,i]
	end

	# header -
	header_array = ["Ticker","scaled μₚ","scaled σₚ","scaled μᵢ","scaled σᵢ","ρᵢ"]
	pretty_table(data_table; header = header_array)
end

# ╔═╡ d54d6407-37ab-4ba5-9ca4-8b5f6135b490
md"""
### Summary and Conclusions
"""

# ╔═╡ 9f4fe50e-1d21-4498-99f0-1fe149be8ff9
md"""
### References
"""

# ╔═╡ 3d578fb2-f09a-11ec-332c-d37a6f84f863
html"""
<style>
main {
    max-width: 1200px;
    width: 70%;
    margin: auto;
    font-family: "Roboto, monospace";
}
a {
    color: blue;
    text-decoration: none;
}
.H1 {
    padding: 0px 30px;
}
</style>"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
JLD2 = "033835bb-8acc-5ee8-8aae-3f567f8a3819"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
PrettyTables = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[compat]
CSV = "~0.10.4"
DataFrames = "~1.3.4"
FileIO = "~1.14.0"
JLD2 = "~0.4.22"
PlutoUI = "~0.7.39"
PrettyTables = "~1.3.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.3"
manifest_format = "2.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings"]
git-tree-sha1 = "873fb188a4b9d76549b81465b1f75c82aaf59238"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.4"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "9be8be1d8a6f44b96482c8af52238ea7987da3e3"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.45.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "fb5f5316dd3fd4c5e7c30a24d50643b73e37cd40"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.10.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "daa21eb85147f72e41f6352a57fccea377e310a9"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.3.4"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "9267e5f50b0e12fdfd5a2455534345c4cf2c7f7a"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.14.0"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "129b104185df66e408edd6625d480b7f9e9823a0"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.18"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "61feba885fac3a407465726d0c330b3055df897f"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.1.2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLD2]]
deps = ["FileIO", "MacroTools", "Mmap", "OrderedCollections", "Pkg", "Printf", "Reexport", "TranscodingStreams", "UUIDs"]
git-tree-sha1 = "81b9477b49402b47fbe7f7ae0b252077f53e4a08"
uuid = "033835bb-8acc-5ee8-8aae-3f567f8a3819"
version = "0.4.22"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "0044b23da09b5608b4ecacb4e5e6c6332f833a7e"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.3.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "8d1f54886b9037091edf146b517989fc4a09efec"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.39"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "db8481cf5d6278a121184809e9eb1628943c7704"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.13"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "5ce79ce186cc678bbb5c5681ca3379d1ddae11a1"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.7.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─76cdf8bd-41ec-44f6-ae7b-2dd1e1d61912
# ╟─68801e9b-1e17-4b85-b39c-352d709bc0c6
# ╟─8ebe17b6-a45d-4e05-9324-7fa13a871a51
# ╠═c5e35f69-9aed-4d22-b7a4-ba12c049b7d4
# ╠═8d8de465-04d5-4303-bdcf-cbed2f5a99e3
# ╠═f465ad78-0ab6-4b1b-addb-b55d3825ff8f
# ╟─252f4d58-1689-44aa-87ad-aa2afe4e7cd6
# ╟─ff8e88eb-2602-42a2-bde9-ffa78ee49cef
# ╠═9b5fd848-f020-4082-935c-ab04fc78fc70
# ╟─52eaa09b-c529-4585-9d73-494253b1fb81
# ╠═7e6fc914-bd13-47c2-9278-78ea51f646ff
# ╠═e814c126-3c01-461b-8093-b5364865390e
# ╠═63d98244-059b-4784-bd1e-c6e07275c61c
# ╠═d430a0c0-42a8-407c-9cf9-687781152592
# ╠═0880e290-8a05-4efc-b605-27154ec086ea
# ╠═9d0d18be-dcfa-489a-ad78-ff132740ec6d
# ╟─8f36a68d-79ed-4b27-9fe8-e7ef9b411e6c
# ╟─d54d6407-37ab-4ba5-9ca4-8b5f6135b490
# ╟─9f4fe50e-1d21-4498-99f0-1fe149be8ff9
# ╟─3d578fb2-f09a-11ec-332c-d37a6f84f863
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
