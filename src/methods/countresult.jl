struct CountSingleResult <: SingleResult
    method::VotingMethod
    winner::Int
    scores::Vector{Pair{Int, Int}}
end

winner(r::CountSingleResult) = r.winner

struct CountMultiResult{N} <: MultiResult
    method::VotingMethod
    winners::NTuple{N, Int}
    scores::Vector{Pair{Int, Int}}
end

winners(r::CountMultiResult) = collect(r.winners)

function Base.getindex(r::Union{CountSingleResult, CountMultiResult}, cand::Int)
    index = findfirst(==(cand), Iterators.map(first, r.scores))
    !isnothing(index) || throw(KeyError(cand))
    last(r.votes[index])
end

function Base.show(io::IO, ::MIME"text/plain", result::CountSingleResult)
    print(io, nameof(typeof(result.method)), "Result: winner ", winner(result))
end

function countresult(method::VotingMethod, scores::Vector{Pair{Int, Int}}, winners::Int=0)
    scores = sort(scores, by=last, rev=true)
    if winners < 1
        maxscore = maximum(last, scores)
        if sum(last.(scores) .== maxscore) > 1
            @warn "Tie between $(first.(scores[last.(scores) .== maxscore])), will (arbitrarily) select $(first(argmax(last, scores)))"
        end
        CountSingleResult(method, first(argmax(last, scores)), scores)
    else
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
end

countresult(method::VotingMethod, scores::Dict{Int, Int}, winners::Int=0) =
    countresult(method, collect(scores), winners)
