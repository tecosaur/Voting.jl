struct Copeland <: VotingMethod end

function elect(::Copeland, ballots::Vector{<:StrictlyRankedBallot})
    candidates = allcandidates(ballots)
    ncand = length(candidates)
    prefmat = preferencematrix(ballots, candidates)
    copescores = zeros(Int, ncand)
    for i in 1:ncand, j in 1:i-1
        iwin = cmp(prefmat[i,j], prefmat[j,i])
        if iwin == 1
            copescores[i] += 1
        elseif iwin == -1
            copescores[j] += 1
        else # iwin == 0
            copescores[i] += 1
            copescores[j] += 1
        end
    end
    scores = candidates .=> copescores
    CountSingleResult(Copeland(), scores)
end
