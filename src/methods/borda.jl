struct Borda <: VotingMethod end

function score(::Borda, ballots::Vector{OrderedBallot}; winners::Int=0)
    allcands = allcandidates(ballots)
    results = Dict(c => 0 for c in allcands)
    for ballot in ballots
        for (i, cand) in enumerate(ballot.ranking)
            results[cand] += length(allcands) - i
        end
    end
    countresult(Borda(), results, winners)
end
