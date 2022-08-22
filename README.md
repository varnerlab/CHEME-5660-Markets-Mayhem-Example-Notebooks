## CHEME-5660 Example Notebooks
This repository holds the example notebooks referenced from the [CHEME 5660 textbook](https://varnerlab.github.io/CHEME-5660-Markets-Mayhem-Book/infrastructure.html). In addition, the notebooks used in the lab section are also available here.

### Installation and Requirments

#### Installing Julia and Pluto
The example notebooks used in lecture, and referenced from the book, are written using the [Pluto notebook package](https://github.com/fonsp/Pluto.jl) and use the [Julia programming language](https://julialang.org).

[Julia](https://julialang.org) is open source, free and runs on all major operating systems and platforms. To install 
[Julia](https://julialang.org) and [Pluto](https://github.com/fonsp/Pluto.jl) please check out the tutorial for 
[MIT 18.S191/6.S083/22.S092 course from Fall 2020](https://computationalthinking.mit.edu/Fall20/installation/).

1. [Install Julia (we are using v1.8, but future versions of Julia should also work)](https://julialang.org/downloads/)
1. [Install Pluto.jl](https://github.com/fonsp/Pluto.jl#installation)
1. Clone this repo:
    ```bash
    git clone https://github.com/varnerlab/CHEME-5660-Markets-Mayhem-Example-Notebooks
    ```
1. From the Julia REPL (`julia`), run Pluto (a web browser window will pop-up):
    ```julia
    julia> using Pluto
    julia> Pluto.run()
    ```
    _Or you can simply type the following in a terminal:_
    ```bash
    julia -E "using Pluto; Pluto.run()"
    ```
1. From Pluto, open one of the `.jl` notebook files located in the `CHEME-5660-Markets-Mayhem-Example-Notebooks/pluto-notebooks/` directory—enjoy!

#### Installing Jupyter
The labs are provided as [Jupyter notebooks](https://jupyter.org); you can find the installation instruction for installing Jupyter [here](https://jupyter.org/install).  For the labs, we use [Julia](https://julialang.org) as our Jupyter notebook kernel; this requires the installation of the [IJulia](https://github.com/JuliaLang/IJulia.jl) package. 

To install [IJulia](https://github.com/JuliaLang/IJulia.jl) from the [Julia REPL](https://docs.julialang.org/en/v1/stdlib/REPL/) press the `]` key to enter [pkg mode](https://pkgdocs.julialang.org/v1/repl/) and the issue the command:

```
add IJulia
```

This will install the [IJulia](https://github.com/JuliaLang/IJulia.jl) package. If you already have Python/Jupyter installed on your machine, this process will also install a
[kernel specification](https://jupyter-client.readthedocs.io/en/latest/kernels.html#kernelspecs)
that tells [Jupyter](https://jupyter.org) how to launch [Julia](https://julialang.org) so we can use it in the notebook. You can then launch the [Jupyter notebook](https://jupyter.org) server the usual
way by running `jupyter notebook` in the terminal.

### Disclaimer and Risks
This content is offered solely for training and informational purposes. No offer or solicitation to buy or sell securities or derivative products, or any investment or trading advice or strategy,  is made, given, or endorsed by the teaching team. 

Trading involves risk. Carefully review your financial situation before investing in securities, futures contracts, options, or commodity interests. Past performance, whether actual or indicated by historical tests of strategies, is no guarantee of future performance or success. Trading is generally inappropriate for someone with limited resources, investment or trading experience, or a low-risk tolerance.  Only risk capital that is not required for living expenses.

You are fully responsible for any investment or trading decisions you make. Such decisions should be based solely on your evaluation of your financial circumstances, investment or trading objectives, risk tolerance, and liquidity needs.
