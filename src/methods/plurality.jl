struct Plurality <: VotingMethod end

function score(::Plurality, ballots::Vector{PluralityBallot{T}}; winners::Int=0) where {T}
    results = Dict{T, Int}()
    for ballot in ballots
        results[ballot.choice] =
            get(results, ballot.choice, 0) + weight(ballot)
    end
    CountMultiResult(Plurality(), results, if winners == 0 length(results) else winners end)
end
