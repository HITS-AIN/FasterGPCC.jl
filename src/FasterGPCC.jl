module FasterGPCC

    using Random

    using ProgressMeter, ThreadTools, Printf

    using Memoization, ThreadSafeDicts

    import GPCC: gpcc, infercommonlengthscale, getprobabilities, simulatetwolightcurves, simulatethreelightcurves, uniformpriordelay

    # Following line makes ProgressMeter work with tmap1

    ProgressMeter.ncalls(::typeof(tmap1), ::Function, args...) = ProgressMeter.ncalls_map(args...)

    include("posteriordelay.jl")

    export posteriordelay

    # re-export GPCC
    export gpcc, infercommonlengthscale, getprobabilities, simulatetwolightcurves, simulatethreelightcurves, uniformpriordelay

end
