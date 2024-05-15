struct CountSingleResult{T} <: SingleResult{T}
    method::VotingMethod
    winner::T
    scores::Vector{Pair{T, Int}}
end

winner(r::CountSingleResult) = r.winner

struct CountMultiResult{T} <: MultiResult{T}
    method::VotingMethod
    winners::Vector{T}
    scores::Vector{Pair{T, Int}}
end

winners(r::CountMultiResult) = r.winners

function Base.getindex(r::Union{CountSingleResult, CountMultiResult}, cand::T) where {T}
    index = findfirst(==(cand), Iterators.map(first, r.scores))
    !isnothing(index) || throw(KeyError(cand))
    last(r.scores[index])
end

Base.keys(r::Union{CountSingleResult, CountMultiResult}) = Iterators.map(first, r.scores)

function Base.show(io::IO, ::MIME"text/plain", result::CountSingleResult)
    print(io, styled"{bold:$(typeof(result.method)) election}: winner is {success:$(winner(result))}")
    nshow = min(length(result.scores), first(displaysize(io)) ÷ 2)
    cpad = maximum(textwidth, map(string ∘ first, @view result.scores[1:nshow]))
    for (i, (cand, score)) in enumerate(@view result.scores[1:nshow])
        print(io, styled"\n  {emphasis:$i.}  $(rpad(cand, cpad))  {shadow:($score)}")
    end
    if nshow < length(result.scores)
        print(io, styled"\n  {shadow:⋮}")
    end
end

function Base.show(io::IO, ::MIME"text/plain", result::CountMultiResult)
    print(io, styled"{bold:$(typeof(result.method)) election}: winners are")
    if get(io, :compact, false)
        print(io, ' ', result.winners)
    else
        wpad = maximum(textwidth, map(string, result.winners))
        for (i, winner) in enumerate(result.winners)
            print(io, styled"\n  {emphasis:$i.}  $(rpad(winner, wpad))  {shadow:($(result[winner]))}")
        end
    end
end

function CountSingleResult(method::VotingMethod, scores::Vector{Pair{T, Int}}) where {T}
    scores = sort(scores, by=last, rev=true)
    maxscore = maximum(last, scores)
    if sum(last.(scores) .== maxscore) > 1
        @warn "Tie between $(first.(scores[last.(scores) .== maxscore])), will (arbitrarily) select $(first(argmax(last, scores)))"
    end
    CountSingleResult(method, first(argmax(last, scores)), scores)
end

CountSingleResult(method::VotingMethod, scores::Dict{T, Int}) where {T} =
    CountSingleResult(method, collect(scores), winners)

Base.convert(::Type{CountSingleResult{T}}, cmr::CountMultiResult{T}) where {T} =
    CountSingleResult(cmr.method, first(cmr.winners), cmr.scores)
Base.convert(::Type{CountSingleResult}, cmr::CountMultiResult{T}) where {T} =
    convert(CountSingleResult{T}, cmr)

CountSingleResult(cmr::CountMultiResult) = convert(CountSingleResult, cmr)

function CountMultiResult(method::VotingMethod, scores::Vector{Pair{T, Int}}, winners::Int=length(scores)) where {T}
    scores = sort(scores, by=last, rev=true)
    winners <= length(scores) ||
        throw(ArgumentError("Cannot select more winners than candidates"))
    threshold = last(scores[winners])
    selection = first.(scores[last.(scores) .>= threshold])
    if sum(last.(scores) .>= threshold) == winners
        CountMultiResult(method, selection, scores)
    else
        tied = first.(scores[last.(scores) .== threshold])
        @warn "Tie between $(tied), will (arbitrarily) pick $(tied ∩ selection)"
        CountMultiResult(method, selection[1:winners], scores)
    end
end

CountMultiResult(method::VotingMethod, scores::Dict{T, Int}, winners::Int=0) where {T} =
    CountMultiResult(method, collect(scores), winners)
