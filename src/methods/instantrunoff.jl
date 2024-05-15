struct InstantRunoff <: VotingMethod
    quota::Float64
    tiebreak::Symbol
    function InstantRunoff(quota::Float64, tiebreak::Symbol)
        0 < quota <= 1 || throw(ArgumentError("Quota ($quota) must be between 0 and 1"))
        tiesystems = (:forwards, :backwards, :borda, :coombs)
        tiebreak ∈ tiesystems ||
            throw(ArgumentError("TieBreak system $tiebreak is not valid, must be one of $tiesystems"))
        new(quota, tiebreak)
    end
end

InstantRunoff(quota::Float64) = InstantRunoff(quota, :backwards)
InstantRunoff(tiebreak::Symbol) = InstantRunoff(0.5, tiebreak)
InstantRunoff() = InstantRunoff(0.5)

struct InstantRunoffResult{T} <: SingleResult{T}
    counts::Vector{Pair{T, Int}}
    rounds::Int
    tiebreaks::Int
end

winner(r::InstantRunoffResult) = first(argmax(last, r.counts))

function elect(irv::InstantRunoff, ballots::Vector{OrderedBallot{T}}) where {T}
    candvotes = Dict{T, Vector{RunoffOrderedBallot}}()
    tallyhistory = Dict{T, Int}[]
    tiebreaks = 0
    for cand in allcandidates(ballots)
        candvotes[cand] = RunoffOrderedBallot[]
    end
    for ballot in ballots
        push!(candvotes[first(ballot.ranking)], (1, ballot))
    end
    totalweight = sum(weight, ballots)
    rvsum(votes) = sum(weight ∘ last, votes, init=0)
    while maximum(sum.(weight ∘ last, (values(candvotes)), init=0)) < totalweight * irv.quota
        push!(tallyhistory, Dict(c => rvsum(v) for (c, v) in candvotes))
        lastcands = foldl(function ((cands, minweight), (newcand, votes))
                              vweight = rvsum(votes)
                              if vweight > minweight
                                  (cands, minweight)
                              elseif vweight == minweight
                                  push!(cands, newcand)
                                  (cands, minweight)
                              else
                                  ([newcand], vweight)
                              end
                          end, candvotes, init=(T[], totalweight)) |> first
        eliminate = if length(lastcands) == 1
            first(lastcands)
        else
            tiebreaks += 1
            if irv.tiebreak === :forwards
                tiebreak_forwards(tallyhistory, lastcands)
            elseif irv.tiebreak === :backwards
                tiebreak_backwards(tallyhistory, lastcands)
            elseif irv.tiebreak === :borda
                tiebreak_borda(ballots, lastcands)
            elseif irv.tiebreak === :coombs
                tiebreak_coombs(ballots, lastcands)
            end
        end
        if isnothing(eliminate)
            @warn "Tie break failed, eliminating the last candidate"
            eliminate = lastcands[argmax(lastcands)]
        end
        elimvotes = candvotes[eliminate]
        delete!(candvotes, eliminate)
        for (rank, ballot) in elimvotes
            while rank < length(ballot.ranking)
                if haskey(candvotes, ballot.ranking[rank+1])
                    push!(candvotes[ballot.ranking[rank+1]], (rank+1, ballot))
                    break
                else
                    rank += 1
                end
            end
        end
    end
    counts = [cand => sum(weight ∘ last, votes) for (cand, votes) in candvotes]
    InstantRunoffResult(sort(counts, by=last, rev=true),
                        length(tallyhistory), tiebreaks)
end

"""
    tiebreak_forwards(rounds::Vector{Dict{T, Int}}, lastcands::Vector{T}) where {T}

Select for elimination the candidate from `lastcands` with the least
(cumulative) votes at the earliest stage in the count (sweeping from the first
round to the last).

If at no point any single candidate of `lastcands` had the least votes,
`nothing` is returned.
"""
function tiebreak_forwards(rounds::Vector{Dict{T, Int}}, lastcands::Vector{T}) where {T}
    round = 0
    scores = zeros(Int, length(lastcands))
    while round < length(rounds) && sum(scores .== minimum(scores)) > 1
        round += 1
        scores += map(cand -> rounds[round][cand], lastcands)
    end
    if round <= length(rounds)
        lastcands[argmin(scores)]
    end
end

"""
    tiebreak_backwards(rounds::Vector{Dict{T, Int}}, lastcands::Vector{T}) where {T}

Select for elimination the candidate from `lastcands` with the least
(cumulative) votes at the most recent prior stage of the count (sweeping from
the last round to the first).

If at no point any single candidate of `lastcands` had the least votes,
`nothing` is returned.
"""
function tiebreak_backwards(rounds::Vector{Dict{T, Int}}, lastcands::Vector{T}) where {T}
    round = length(rounds)
    scores = zeros(Int, length(lastcands))
    while round > 0 && sum(scores .== minimum(scores)) > 1
        scores += map(cand -> rounds[round][cand], lastcands)
        round -= 1
    end
    if round > 0
        lastcands[argmin[scores]]
    end
end

"""
    tiebreak_borda(ballots::Vector{OrderedBallot{T}}, lastcands::Vector{T}) where {T}

Select for elimination the candidate of `lastcands` with the lowest Borda count,
calculated from `ballots`.

If no single candidate of `lastcands` has the lowest Borda count, `nothing` is
returned.
"""
function tiebreak_borda(ballots::Vector{OrderedBallot{T}}, lastcands::Vector{T}) where {T}
    borda_score = filter((c, _)::Pair -> c in lastcands,
                         elect(Borda(), ballots).votes)
    if sum(last.(borda_score) .== minimum(last.(borda_score))) == 1
        first(argmin(last, borda_score))
    end
end

"""
    tiebreak_coombs(ballots::Vector{OrderedBallot{T}}, lastcands::Vector{T}) where {T}

Select for elimination the candidate of `lastcands` with the most last-place votes.
Should this result in ties, the (n-1)th place votes are added etc. until a single
candidate has the most cumulative last-place votes.

Should no single candidate of `lastcands` have the most votes after considering all
places, `nothing` is returned.
"""
function tiebreak_coombs(ballots::Vector{OrderedBallot{T}}, lastcands::Vector{T}) where {T}
    place = maximum(b -> length(b.ranking), ballots) + 1
    placescores = Dict(c => 0 for c in lastcands)
    while place > 0 && sum(values(placescores) .== minimum(values(placescores))) > 1
        place -= 1
        for ballot in ballots
            if length(ballot.ranking) >= place && haskey(placescores, ballot.ranking[place])
                placescores[ballot.ranking[place]] += 1
            end
        end
    end
    if place > 0
        first(argmax(last, placescores))
    end
end
