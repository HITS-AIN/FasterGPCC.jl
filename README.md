<h1 align="center">FasterGPCC.jl</h1>
<p align="center">
  <img width="253" height="165" src=logo.png>
</p>



## ℹ What is this?

This is a Julia implementation that speeds up the Gaussian Process Cross Correlation (GPCC) method introduced in 

[*A Gaussian process cross-correlation approach to time delay estimation for reverberation mapping of active galactic nuclei*](https://github.com/HITS-AIN/GPCCpaper).

The original GPCC implementation can be found [here](https://github.com/HITS-AIN/GPCC.jl). 

## 💾 Installation

Apart from cloning, an easy way of using the package is the following:

1 - Add the registry [AINJuliaRegistry](https://github.com/HITS-AIN/AINJuliaRegistry)

2 - Switch into "package mode" with `]` and add the package with
```
add FasterGPCC
```


## 🚀 An important note about performance

*(This note is not specific to the GPCC package; it applies in general whenever BLAS threads run concurrently to julia threads.)*

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
using GPCC, LinearAlgebra, ThreadPinning
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
using PyPlot # must be independently installed
figure("Delay for two simulated lightcurves")
plot(candidatedelays, P)
```

-------
### Three-lightcurves example

We show how the above estimation of the posterior delay can be performed for three lightcurves:
```
using GPCC, LinearAlgebra, ThreadPinning
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
using GPCC, LinearAlgebra, ThreadPinning
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



## ▶ How to fit a dataset with `gpcc`

We show how to fit the GPCC model and make predictions with it. To that end we use the function `gpcc`. Options for `gpcc` can be queried in help mode.

```
using GPCC

tobs, yobs, σobs, truedelays = simulatetwolightcurves();

# We first determine the lengthscale for the GPCC with the following call.
# We choose the rbf kernel. Other choices are GPCC.OU, GPCC.matern32, GPCC.matern52

ρ = infercommonlengthscale(tobs, yobs, σobs; kernel = GPCC.rbf, iterations = 1000)


# We choose the same kernel as the one used for inferring the length scale.
# Choosing a different kernel may lead to non-sensical results.
# We fit the model for the given the true delays above. 
# Note that without loss of generality we can always set the delay of the 1st band equal to zero
# The optimisation of the model runs for a maximum of 1000 iterations.

loglikel, α, postb, pred = gpcc(tobs, yobs, σobs; kernel = GPCC.rbf, delays = truedelays, iterations = 1000, ρfixed = ρ)
```

The call returns three outputs:
- the marginal log likelihood `loglikel` reached by the optimiser.
- a vector of scaling coefficients $\alpha$.
- posterior distribution `postb` (of type [MvNormal](https://juliastats.org/Distributions.jl/stable/multivariate/#Distributions.MvNormal)) for shift $b$.
- a function `pred` for making predictions.

We show below how function `pred` can be used both for making predictions and calculating the predictive likelihood.

## ▶ How to make predictions

Having fitted the model to the data, we can now make predictions. We first define the interval over which we want to predict and use `pred`:
```
t_test = collect(0:0.2:62);
μpred, σpred = pred(t_test);
```

Both `μpred` and `σpred` are arrays of arrays. The $l$-th inner array refers to predictions for the $l$-th band, e.g. `μpred[2]` and `σpred[2]` hold respectively the mean prediction and standard deviation of the $2$-band. We plot the predictions for all bands:


<p align="center">
  <img src=simulateddata_predictions.png>
</p>

```
using PyPlot # must be independently installed, other plotting packages can be used instead

colours = ["blue", "orange"] # define colours

figure()
for i in 1:2
    plot(tobs[i], yobs[i], "o", color=colours[i])
    plot(t_test, μpred[i], "-", color=colours[i])
    fill_between(t_test, μpred[i] + σpred[i], μpred[i] - σpred[i], color=colours[i], alpha=0.2) # plot uncertainty tube
end

```




## ▶ How to calculate log-likelihood on test data

Suppose we want to calculate the log-likelihood on some new data (test data perhaps):
```
ttest = [[9.0; 10.0; 11.0], [9.0; 10.0; 11.0]]
ytest = [ [6.34, 5.49, 5.38], [13.08, 12.37, 15.69]]
σtest = [[0.34, 0.42, 0.2], [0.87, 0.8, 0.66]]

pred(ttest, ytest, σtest)
```


❗ As a general note, running GPCC on more than four light curves and for a large number of candidate delays can be a very lengthy computation constrained by the available CPU and memory resources! This is because GPCC will try out in a brute force manner all possible delay combinations. We may address the efficiency of this computation in the future.


