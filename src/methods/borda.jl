struct Borda <: VotingMethod end

function score(::Borda, ballots::Vector{<:StrictlyRankedBallot}; winners::Int=0)
    allcands = allcandidates(ballots)
    results = Dict(c => 0 for c in allcands)
    for ballot in ballots
        for (i, cand) in enumerate(ranking(ballot))
            results[cand] += (length(allcands) - i) * weight(ballot)
        end
    end
    CountMultiResult(Borda(), results, if winners == 0 length(allcands) else winners end)
end
