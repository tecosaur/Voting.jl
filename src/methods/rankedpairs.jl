struct RankedPairs <: VotingMethod end

struct RankedPairsResult{T} <: SingleResult{T}
    winner::T
    preferences::Vector{Tuple{Pair{T, T}, Int}}
end

winner(r::RankedPairsResult) = r.winner

struct RepeatedRankedPairsResult{T} <: MultiResult{T}
    winners::Vector{T}
    preferences::Vector{Tuple{Pair{T, T}, Int}}
    prefmat::Matrix{Int}
end

winners(r::RepeatedRankedPairsResult) = r.winners

function preferencepairs(prefmat::Matrix{Int}, candidates::AbstractVector{T}) where {T}
    preferences = Tuple{Pair{T, T}, Int}[]
    for i in axes(prefmat, 1), j in axes(prefmat, 2)
        push!(preferences, (candidates[i] => candidates[j], prefmat[i, j]))
    end
    filter!(>(0) ∘ last, preferences)
    sort(preferences, by=last, rev=true)
end

function score(::RankedPairs, ballots::Vector{<:StrictlyRankedBallot{T}}; winners::Int=0) where {T}
    winlist = T[]
    candidates = allcandidates(ballots)
    prefmat = preferencematrix(ballots, candidates)
    preferences = preferencepairs(prefmat, candidates)
    while length(winlist) < max(1, winners)
        edges = Set{Pair{T, T}}()
        children = Set{T}()
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
