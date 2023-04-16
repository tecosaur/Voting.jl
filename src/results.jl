abstract type Result end

abstract type SingleResult <: Result end

abstract type MultiResult <: Result end

struct ResultContext{R <: Result, C}
    result::R
    candidates::Vector{C}
end

winner(r::ResultContext{<:SingleResult}) = r.candidates[winner(r.result)]
winners(r::ResultContext{<:MultiResult}) = r.candidates[winners(r.result)]

Base.:(==)(a::R, b::R) where { R <: Result } =
    all(f -> getfield(a, f) == getfield(b, f), fieldnames(R))

function Base.show(io::IO, ::MIME"text/plain", result::SingleResult)
    print(io, nameof(typeof(result)), ": winner ", winner(result))
end
