module FasterGPCC

    using GPCC, Random

    using ProgressMeter, ThreadTools, Printf

    using Memoization, ThreadSafeDicts

    # Following line makes ProgressMeter work with tmap1

    ProgressMeter.ncalls(::typeof(tmap1), ::Function, args...) = ProgressMeter.ncalls_map(args...)

    include("posteriordelay.jl")

    export posteriordelay

end
