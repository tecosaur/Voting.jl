abstract type Result{T} end

abstract type SingleResult{T} <: Result{T} end

abstract type MultiResult{T} <: Result{T} end

winner(r::MultiResult) = first(winners(r))

struct ResultContext{R <: Result{Int}, C}
    result::R
    candidates::Vector{C}
end

winner(r::ResultContext{<:SingleResult}) = r.candidates[winner(r.result)]
winners(r::ResultContext{<:MultiResult}) = r.candidates[winners(r.result)]

Base.:(==)(a::R, b::R) where { R <: Result } =
    all(f -> getfield(a, f) == getfield(b, f), fieldnames(R))

function Base.show(io::IO, ::MIME"text/plain", result::SingleResult)
    print(io, nameof(typeof(result)), styled": winner is {success:$(winner(result))}")
end

function Base.show(io::IO, ::MIME"text/plain", result::MultiResult)
    print(io, nameof(typeof(result)), styled": winners are")
    for (i, winner) in enumerate(winners(result))
        print(io, styled"\n  {emphasis:$i.}  $winner")
    end
end
