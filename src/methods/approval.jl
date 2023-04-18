struct Approval <: VotingMethod end

function score(::Approval, ballots::Vector{ApprovalBallot}; winners::Int=0)
    results = Dict(c => 0 for c in allcandidates(ballots))
    for ballot in ballots, choice in ballot.choices
        results[choice] += weight(ballot)
    end
    countresult(Approval(), results, winners)
end
