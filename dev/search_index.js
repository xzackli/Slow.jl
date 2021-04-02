var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = Slow","category":"page"},{"location":"#Slow","page":"Home","title":"Slow","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for Slow. This package attempts to address a tension between understandability and efficiency in scientific computing.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The naive implementation of a scientific calculation in Julia is usually good enough. However, a factor of sim 2-100 in performance can be obtained by thinking about how modern computers work. For example – reducing allocations by keeping buffers around, making calculations cache-friendly, and grouping similar calculations with SIMD.\nThe naive implementation and the optimized numerical version can look very different. The optimized version is usually the one that people call from outside the package, but the naive implementation will resemble the equations in the paper.\nIt's useful to keep around the naive implementation. If you're developing some extension to the code, being able to start with a paste of the naive but correct implementation can be very handy. It's also informative for new contributors to packages.\nIt can be nice to write unit tests which compare the naive and fast implementations.","category":"page"},{"location":"","page":"Home","title":"Home","text":"This package exports @slowdef to define a slower, naive implementation of a function, and call it with @slow. Here's an example, where we implement a slow version of a function, and a fast version. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Slow\n\n# fake naive implementation\n@slowdef function f(x)\n    sleep(1)  \n    return sin(x)\nend\n\n# fake fast implementation\nf(x) = sin(x)\n\n@time @slow f(1.0)\n@time f(1.0)","category":"page"},{"location":"","page":"Home","title":"Home","text":"The function definition func(args...) = ... prefaced by @slowdef is replaced with func(::Slow.SlowImplementation, args...) = .... This is a shortcut for a common Julia multimethod pattern, where different implementations dispatch on the first argument. I think the magic number here is two (fast and slow) – if you have three implementations, you should probably just define your own multimethod type.","category":"page"},{"location":"","page":"Home","title":"Home","text":"This macro can help with development too – one common pattern of writing code is to (first) make it correct and (then) make it fast. By keeping separate fast and @slow implementations, one can more easily resist premature optimization and micro-optimizations.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [Slow]","category":"page"},{"location":"#Slow.@slow-Tuple{Any}","page":"Home","title":"Slow.@slow","text":"@slow\n\nCall a slow version of a function that was defined with @slowdef. ```\n\n\n\n\n\n","category":"macro"},{"location":"#Slow.@slowdef-Tuple{Any}","page":"Home","title":"Slow.@slowdef","text":"@slowdef\n\nDefine a slow version of a function which can be called with @slow.\n\n\n\n\n\n","category":"macro"},{"location":"#Slow.@slowtest-Tuple{Any}","page":"Home","title":"Slow.@slowtest","text":"@slowtest\n\nShortcut for @test (@slow func(args...)) == func(args...).\n\n\n\n\n\n","category":"macro"}]
}
