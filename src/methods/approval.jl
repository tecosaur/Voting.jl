struct Approval <: VotingMethod end

function score(::Approval, ballots::Vector{ApprovalBallot}; winners::Int=0)
    allcands = allcandidates(ballots)
    results = Dict(c => 0 for c in allcands)
    for ballot in ballots, choice in ballot.choices
        results[choice] += weight(ballot)
    end
    CountMultiResult(Approval(), results, if winners == 0 length(allcands) else winners end)
end
