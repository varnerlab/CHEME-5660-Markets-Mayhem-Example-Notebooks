### A Pluto.jl notebook ###
# v0.19.5

using Markdown
using InteractiveUtils

# ╔═╡ 588d24c2-0ee5-4a37-9a7d-2561773032cc
md"""
## CHEME 5660: Calculating the Yield to Maturity (YTM) of a United States Treasury Bond
Jeffrey D. Varner, Smith School of Chemical and Biomolecular Engineering, Cornell University, Ithaca, NY 14850
"""

# ╔═╡ d1f05cea-1c66-4118-bda5-99ad24a969a7
md"""
### Introduction
"""

# ╔═╡ f3c06392-ba32-40fb-b964-62c5b3ce4dd2
md"""
### Problem Statement
"""

# ╔═╡ 3bbd8f67-8331-49fd-bb81-43a3f62a817d
md"""
### Materials and Methods
"""

# ╔═╡ 3265342a-041f-40ca-94d1-c2806940c70d
md"""
### Results
"""

# ╔═╡ b425f85d-7746-4c3a-abd3-87a12634fcd0
md"""
### Discussion
"""

# ╔═╡ d3042a7e-683c-4ab8-9910-2f024c125ef9
md"""
### Additional Resources
"""

# ╔═╡ d75fbd10-181c-43a8-bd6c-3ebc7b6eda8f
md"""
#### Disclaimer and Risks
This content is offered solely for training and  informational purposes. No offer or solicitation to buy or sell securities or derivative products, or any investment or trading advice or strategy,  is made, given, or endorsed by the teaching team. 

Trading involves risk. Carefully review your financial situation before investing in securities, futures contracts, options, or commodity interests. Past performance, whether actual or indicated by historical tests of strategies, is no guarantee of future performance or success. Trading is generally inappropriate for someone with limited resources, investment or trading experience, or a low-risk tolerance.  Only risk capital that is not required for living expenses.

You are fully responsible for any investment or trading decisions you make. Such decisions should be based solely on your evaluation of your financial circumstances, investment or trading objectives, risk tolerance, and liquidity needs.
"""

# ╔═╡ 2fb7f5c0-ff1a-11ec-2208-75d3ea4b523c
html"""
<style>
main {
    max-width: 1200px;
    width: 64%;
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
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.3"
manifest_format = "2.0"

[deps]
"""

# ╔═╡ Cell order:
# ╟─588d24c2-0ee5-4a37-9a7d-2561773032cc
# ╟─d1f05cea-1c66-4118-bda5-99ad24a969a7
# ╟─f3c06392-ba32-40fb-b964-62c5b3ce4dd2
# ╟─3bbd8f67-8331-49fd-bb81-43a3f62a817d
# ╟─3265342a-041f-40ca-94d1-c2806940c70d
# ╟─b425f85d-7746-4c3a-abd3-87a12634fcd0
# ╟─d3042a7e-683c-4ab8-9910-2f024c125ef9
# ╟─d75fbd10-181c-43a8-bd6c-3ebc7b6eda8f
# ╟─2fb7f5c0-ff1a-11ec-2208-75d3ea4b523c
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
