struct RankedPairs <: VotingMethod end

struct RankedPairsResult <: SingleResult
    winner::Int
    preferences::Vector{Tuple{Pair{Int, Int}, Int}}
end

winner(r::RankedPairsResult) = r.winner

struct RepeatedRankedPairsResult <: VotingMethod
    winners::Vector{Int}
    preferences::Vector{Tuple{Pair{Int, Int}, Int}}
    prefmat::Matrix{Int}
end

winners(r::RepeatedRankedPairsResult) = r.winners

function score(::RankedPairs, ballots::Vector{<:StrictlyRankedBallot}; winners::Int=0)
    winlist = Int[]
    prefmat = preferencematrix(ballots)
    preferences = Tuple{Pair{Int, Int}, Int}[]
    for i in axes(prefmat, 1), j in axes(prefmat, 2)
        push!(preferences, (i => j, prefmat[i, j]))
    end
    filter!(>(0) ∘ last, preferences)
    sort!(preferences, by=last, rev=true)
    candidates = allcandidates(ballots)
    while length(winlist) < max(1, winners)
        edges = Set{Pair{Int, Int}}()
        children = Set{Int}()
        for ((i, j), _) in preferences
            if i ∉ children && (j => i) ∉ edges
                push!(children, j)
                push!(edges, i => j)
            end
        end
        thewinners = setdiff(candidates, children)
        if length(winlist) + length(thewinners) <= max(1, winners)
            append!(winlist, thewinners)
        elseif length(thewinners) != 1
            @warn "No single winner, tie between $thewinners"
            push!(winlist, first(winners))
        else
            error("This shouldn't happen!")
        end
        if length(winlist) < winners
            filter!(∉(thewinners) ∘ last ∘ first, preferences)
            filter!(∉(thewinners) ∘ first ∘ first, preferences)
            candidates = setdiff(candidates, thewinners)
        end
    end
    if winners == 0
        RankedPairsResult(first(winlist), preferences)
    else
        RepeatedRankedPairsResult(winlist, preferences, prefmat)
    end
end
