struct RankedPairs <: VotingMethod end

struct RankedPairsResult <: SingleResult
    winner::Int
    preferences::Vector{Tuple{Pair{Int, Int}, Int}}
end

winner(r::RankedPairsResult) = r.winner

function score(::RankedPairs, ballots::Vector{OrderedBallot})
    prefmat = preferencematrix(ballots)
    preferences = Tuple{Pair{Int, Int}, Int}[]
    for i in axes(prefmat, 1), j in axes(prefmat, 2)
        push!(preferences, (i => j, prefmat[i, j]))
    end
    filter!(>(0) ∘ last, preferences)
    sort!(preferences, by=last, rev=true)
    edges = Set{Pair{Int, Int}}()
    children = Set{Int}()
    for ((i, j), _) in preferences
        if i ∉ children && (j => i) ∉ edges
            push!(children, j)
            push!(edges, i => j)
        end
    end
    winners = setdiff(allcandidates(ballots), children)
    if length(winners) != 1
        @warn "No single winner, tie between $winners"
    end
    RankedPairsResult(first(winners), preferences)
end
