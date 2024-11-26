<h1 align="center">FasterGPCC.jl</h1>
<p align="center">
  <img width="253" height="165" src=logo.png>
</p>



## ℹ What is this?

This is a Julia implementation that speeds up the Gaussian Process Cross Correlation (GPCC) via a heuristic. The original GPCC implementation can be found [here](https://github.com/HITS-AIN/GPCC.jl). 

## 💾 Installation

Apart from cloning, an easy way of using the package is the following:

1 - Add the registry [AINJuliaRegistry](https://github.com/HITS-AIN/AINJuliaRegistry)

2 - Switch into "package mode" with `]` and add the package with
```
add FasterGPCC
```

The package exports the methods `posteriordelay`. It also re-exports the methods `simulatetwolightcurves`, `simulatethreelightcurves`, `infercommonlengthscale`, `gpcc` and `uniformpriordelay`.

## 🚀 An important note about performance

*(This note is not specific to the FasterGPCC package; it applies in general whenever BLAS threads run concurrently to julia threads.)*

The package supports the parallel evaluation of candidate delays.
To that end, start julia with multiple threads. For instance, you can start julia with 8 threads using `julia -t8`.
We recommend to use as many threads as physical cores.

To get the most performance, please read this note [here](https://carstenbauer.github.io/ThreadPinning.jl/dev/explanations/blas/) concerning issues when running multithreaded code that makes use of BLAS calls. In most cases, the following instructions suffice:
```
using LinearAlgebra
BLAS.set_num_threads(1) # Set the number of BLAS threads to 1

using ThreadPinning # must be indepedently installed
pinthreads(:cores) # allows you to pin Julia threads to specific CPU-threads 
```

Unless you are using the Intel MKL, we recommend to always use the above code before estimating delays.


## ▶ How to estimate delays

### Two-lightcurves example

Start Julia with multiple threads.
We simulate some data:
```
using GPCC, FasterGPCC, LinearAlgebra, ThreadPinning
BLAS.set_num_threads(1)
pinthreads(:cores) 

tobs, yobs, σobs, truedelays = simulatetwolightcurves()
```

We define a set of candidate delays that we would like to test:
```
candidatedelays = LinRange(0.0, 10.0, 100)
```

Having generated the simulated data, we will now estimate the delays. To that end we use the function `posteriordelay`:
```
 P = posteriordelay(tobs, yobs, σobs, candidatedelays; kernel = GPCC.rbf, iterations = 1000)
```

The returned `P` contains the probability of each candidate delay. We can plot the result with:
```
using Plots # must be independently installed
plot(candidatedelays, P)
```

-------
### Three-lightcurves example

We show how the above estimation of the posterior delay can be performed for three lightcurves:
```
using GPCC, FasterGPCC, LinearAlgebra, ThreadPinning
BLAS.set_num_threads(1)
pinthreads(:cores) 

tobs, yobs, σobs, truedelays = simulatethreelightcurves()

candidatedelays = LinRange(0.0, 6.0, 100)
P = posteriordelay(tobs, yobs, σobs, candidatedelays; kernel = GPCC.rbf, iterations = 1000)

size(P) # P is now a matrix, above it was a vector

using PyPlot # must be indepedently installed, other plotting packages can be used instead
figure();title("marginals")
plot(candidatedelays, vec(sum(P,dims=[2;3])))
plot(candidatedelays, vec(sum(P,dims=[1;3])))

figure(); title("joint distribution")
pcolor(candidatedelays, candidatedelays, P)
```

The above examples can be extended to more than three lightcurves.


## ▶ Estimate delays for real datasets

In the following script, we estimate the delays for a number of objects where two light curves are available.
The real data are provided in the package [GPCCData.jl](https://github.com/HITS-AIN/GPCCData.jl).
After stating Julia with multiple threads, we execute the following script:
```
using GPCC, FasterGPCC, LinearAlgebra, ThreadPinning
BLAS.set_num_threads(1)
pinthreads(:cores)

using GPCCData # needs to be indepedently installed, provides access to real data
using PyPlot # needs to be indepedently installed

let # WARMUP - Julia precompiles code

  tobs, yobs, σobs, truedelays = simulatetwolightcurves()
  candidatedelays = LinRange(0.0,4.0,3)
  posteriordelay(tobs, yobs, σobs, candidatedelays; kernel = GPCC.rbf);

end

candidatedelays = collect(0.0:0.1:60.0)

for i in 1:5
       tobs, yobs, σobs, lambda, = readdataset(source = listdatasets()[i])
       P = posteriordelay(tobs, yobs, σobs, candidatedelays; kernel = GPCC.OU)
       figure(); title(listdatasets()[i])
       plot(candidatedelays, P)
end
```
