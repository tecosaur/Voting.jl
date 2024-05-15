struct STAR <: VotingMethod end

struct STARResult{T} <: Result{T}
    runoff::Vector{Pair{T, Int}}
    scores::Vector{Pair{T, Int}}
end

winner(r::STARResult) = first(argmax(last, r.runoff))

function elect(::STAR, ballots::Vector{ScoredBallot{T}}) where {T}
    allcands = allcandidates(ballots)
    scores = Dict(c => 0 for c in allcands)
    for ballot in ballots, (cand, cscore) in ballot.scores
        scores[cand] += cscore * weight(ballot)
    end
    rankedscores = sort(values(scores) |> scores, rev=true)
    runoff = if sum(rankedscores .== first(rankedscores)) == 1
        filter(cand -> scores[cand] in rankedscores[1:2], allcands)
    elseif sum(rankedscores .== first(rankedscores)) == 2
        filter(cand -> scores[cand] == first(rankedscores), allcands)
    else
        @warn "More than two tied first-place candidates"
        filter(cand -> scores[cand] == first(rankedscores), allcands)
    end
    highballots = Dict(c => 0 for c in runoff)
    scorethreshold = maximum(maximum(values(b.scores)) for b in ballots)
    while scorethreshold > 0 && sum(values(highballots) .== maximum(values(highballots))) > 1
        for ballot in ballots, cand in runoff
            if ballot.score[cand] == scorethreshold
                highballots[cand] += 1
            end
        end
        scorethreshold -= 1
    end
    STARResult(sort(collect(highballots), by=last, rev=true),
               rankedscores)
end
