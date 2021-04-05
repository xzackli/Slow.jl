module SlowMacro

export @slowdef, @slow

using MacroTools
using MacroTools: postwalk
using Cassette
using Test

struct SlowImplementation end
struct SlowAll end
Cassette.@context SlowCtx

# used as SlowMacro.overdub, etc. in macros to shorten the expressions a bit
const overdub = Cassette.overdub
const recurse = Cassette.recurse

# generate a standard SlowCtx context (no hooks!)
slowctx(valT) = Cassette.disablehooks(SlowCtx(metadata=valT))


"""
    @slowdef [function definition]

Define a slow version of a function which can be called with [`@slow`](@ref). To use,
preface a method definition with this macro.

# Examples
```julia
using SlowMacro

# define a slow version of x
@slowdef f(x) = println("slow")
f(x) = println("fast")

@slow f(0.0)  # prints "slow"
f(0.0)        # prints "fast"

# you can also use the full function definition form, of course
@slowdef function g(x::T) where T
    return x
end
```
"""
macro slowdef(func)
    funcdef = splitdef(func)
    funcargs = copy(funcdef[:args])
    pushfirst!(funcdef[:args], :(::SlowMacro.SlowImplementation))

    funcname = funcdef[:name]
    newfuncdef = MacroTools.combinedef(funcdef)

    if length(funcdef[:kwargs]) > 0  # we have kwargs
        overdub_block = quote
            SlowMacro.overdub(ctx::SlowMacro.SlowCtx{Val{T}}, kwf::Core.kwftype(typeof($funcname)),
                kwargs::Any, func::typeof($funcname), $(funcargs...)) where {T <: SlowMacro.SlowAll} =
                    SlowMacro.recurse(ctx, kwf, kwargs, func, SlowMacro.SlowImplementation(), $(funcargs...))
            SlowMacro.overdub(ctx::SlowMacro.SlowCtx{Val{T}}, kwf::Core.kwftype(typeof($funcname)),
                kwargs::Any, func::T, $(funcargs...)) where {T <: typeof($funcname)} =
                    SlowMacro.recurse(ctx, kwf, kwargs, func, SlowMacro.SlowImplementation(), $(funcargs...))
        end
    else  # just args
        overdub_block = quote
            SlowMacro.overdub(ctx::SlowMacro.SlowCtx{Val{T}}, func::typeof($funcname),
                $(funcargs...)) where {T <: SlowMacro.SlowAll} =
                SlowMacro.recurse(ctx, func, SlowMacro.SlowImplementation(), $(funcargs...))
            SlowMacro.overdub(ctx::SlowMacro.SlowCtx{Val{T}}, func::T,
                $(funcargs...)) where {T <: typeof($funcname)} =
                SlowMacro.recurse(ctx, func, SlowMacro.SlowImplementation(), $(funcargs...))
        end
    end

    return esc(Expr(:block, newfuncdef, overdub_block))
end

# used to convert kwarg iterator to NamedTuple
extractkwargs(; kwargs...) = values(kwargs)

# functions for overdubbing
slowall(f, args...) = overdub(slowctx(Val(SlowAll)), f, args...)
slowone(f, slow_func, args...) = overdub(slowctx(Val(typeof(slow_func))), f, args...)


"""
    @slow (expr)
    @slow (func) (expr)

Call a slow version of a function that was defined with [`@slowdef`](@ref).
Preface an expression in order to perform a Cassette pass on every top-level function
in the expression, recursively looking for functions with @slowdef implementations.
If a function is passed before the expression (separated by a space), only that
function is slowed.

# Examples

Calling `@slow` on an expression calls every function with a slow implementation
in the nested sequence of calls for that expression.

```julia
@slowdef s(x) = begin println("slow s"); return sin(x) end
s(x) = begin println("fast s"); return sin(x) end

# call the slow version
@slow s(0.)  # prints "slow s"
s(0.)        # prints "fast s"
```

This works for slow functions that are nested inside other functions in the expression.

```julia
@slowdef f(x) = begin println("slow f"); return s(x)^2 end
f(x) = begin println("fast f"); return s(x)^2 end

# call the slow version
@slow f(0.)  # prints "slow f", "slow s"
f(0.)        # prints "fast f", "fast s"
```

You can target individual functions for slowing by passing a function after SlowMacro.

```julia
@slow s f(0.)  # prints "fast f", "slow s"
@slow f f(0.)  # prints "slow f", "fast s"
```
"""
macro slow(ex)
    newex = postwalk(ex) do x
        if @capture(x, f_(args__; kwargs__))
            return quote
                SlowMacro.slowall(Core.kwfunc($(esc(f))),
                    SlowMacro.extractkwargs(;$(kwargs...)), $(esc(f)), $(args...))
            end
        elseif @capture(x, f_(args__))
            return quote
                SlowMacro.slowall($(esc(f)), $(args...))
            end
        else
            return x
        end
    end
    return newex
end


# slow down a specific function.
macro slow(slow_func, ex)
    newex = postwalk(ex) do x
        if @capture(x, f_(args__; kwargs__))
            return quote
                SlowMacro.slowone(Core.kwfunc($(esc(f))), $(esc(slow_func)),
                    SlowMacro.extractkwargs(;$(kwargs...)), $(esc(f)), $(args...))
            end
        elseif @capture(x, f_(args__))
            return quote
                SlowMacro.slowone($(esc(f)), $(esc(slow_func)), $(args...))
            end
        else
            return x
        end
    end
end


# Shortcut for `@test (@slow func(args...)) == func(args...)`.
macro slowtest(func)
    if @capture(func, f_(xs__))
        newex = quote
            @test $(esc(func)) == $(esc(f))(SlowMacro.SlowImplementation(), $(xs...))
        end
        return newex
    end
    throw(ArgumentError("@slowtest must be applied to a function, i.e. @slowtest( f(x) ) or @slowtest f(x)"))
end

end  # module
