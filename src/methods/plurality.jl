struct Plurality <: VotingMethod end

function score(::Plurality, ballots::Vector{PluralityBallot}; winners::Int=0)
    results = Dict{Int, Int}()
    for ballot in ballots
        results[ballot.choice] =
            get(results, ballot.choice, 0) + 1
    end
    countresult(Plurality(), results, winners)
end
