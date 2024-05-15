abstract type Ballot{T} end

abstract type UnrankedBallot{T} <: Ballot{T} end

abstract type RankedBallot{T} <: Ballot{T} end

abstract type StrictlyRankedBallot{T} <: RankedBallot{T} end

"""
    weight(ballot::Ballot)

Return the weight of `ballot`. The weight is normally a positive integer
representing the number of voters who cast the ballot.
"""
weight(::Ballot) = 1

"""
    reweight(ballot::Ballot, weight::Int) -> Ballot

Return a new ballot identical to `ballot` but with a new `weight`.
"""
function reweight end

"""
    indexballot(ballot::Ballot{T}, candidates::Vector{T}) -> Ballot{Int}

Convert `ballot` to a more memory efficient representation, by using integers to
represent the choices in the ballot(s). The `candidates` vector is used to map
the integers back to the original choices.
"""
function indexballot end

"""
    allcandidates(ballot::Ballot{T}) -> Vector{T}

Return an ordered vector of all candidates known to `ballot`.
"""
function allcandidates end

function allcandidates(bs::Vector{<:Ballot{T}}) where {T}
    cands = Dict{T, Int}()
    for b in bs, c in allcandidates(b)
        if !haskey(cands, c)
            cands[c] = length(cands) + 1
        end
    end
    vals = Dict(v => k for (k, v) in cands)
    [vals[i] for i in 1:length(cands)]
end

struct BallotContext{B <: Ballot, C}
    ballot::B
    candidates::Vector{C}
end

weight(b::BallotContext) = weight(b.ballot)
reweight(b::BallotContext, weight::Int) =
    BallotContext(reweight(b.ballot, weight), b.candidates)
allcandidates(b::BallotContext) = b.candidates

# ------------------
# Approval Ballot
# ------------------

struct ApprovalBallot{T} <: UnrankedBallot{T}
    choices::Set{T}
    count::Int
end

ApprovalBallot(choices::Set{T}) where {T} = ApprovalBallot(choices, 1)

weight(b::ApprovalBallot) = b.count
reweight(b::ApprovalBallot, newcount::Int) =
    ApprovalBallot(b.choices, newcount)

allcandidates(b::ApprovalBallot) = collect(b.choices)

function indexballot(b::ApprovalBallot{T}, candidates::Vector{T}) where {T}
    indices = indexin(b.choices, candidates)
    all(!isnothing, indices) ||
        throw(ArgumentError(lazy"Choices $(choices[isnothing.(indices)]) do not exist in the candidate list"))
    ApprovalBallot(Set(Vector{Int}(indices)), weight(b))
end

# ------------------
# Plurality Ballot
# ------------------

struct PluralityBallot{T} <: UnrankedBallot{T}
    choice::T
    count::Int
end

PluralityBallot(choice::T) where {T} = PluralityBallot(choice, 1)

weight(b::PluralityBallot) = b.count
reweight(b::PluralityBallot, newcount::Int) =
    PluralityBallot(b.choice, newcount)

allcandidates(b::PluralityBallot) = [b.choice]

function indexballot(b::PluralityBallot{T}, candidates::Vector{T}) where {T}
    index = findfirst(==(b.choice), candidates)
    isnothing(index) || throw(ArgumentError(lazy"Choice $(sprint(show, b.choice)) did not exist in candidate list"))
    PluralityBallot(index::Int, weight(b))
end

# ------------------
# Scored Ballot
# ------------------

struct ScoredBallot{T} <: RankedBallot{T}
    scores::Dict{T, Int}
    count::Int
end

ScoredBallot(scores::Dict{T, Int}) where {T} = ScoredBallot(scores, 1)

weight(b::ScoredBallot) = b.count
reweight(b::ScoredBallot, newcount::Int) =
    ScoredBallot(b.scores, newcount)

allcandidates(b::ScoredBallot) = collect(keys(b.scores))

function indexballot(b::ScoredBallot{T}, candidates::Vector{T}) where {T}
    indices = indexin(keys(b.scores), candidates)
    all(!isnothing, indices) ||
        throw(ArgumentError(lazy"Choices $(keys(b.scores)[isnothing.(indices)]) do not exist in the candidate list"))
    ScoredBallot(Dict(zip(Vector{Int}(indices), values(b.scores))), weight(b))
end

# ------------------
# Ordered Ballot
# ------------------

struct OrderedBallot{T} <: StrictlyRankedBallot{T}
    ranking::Vector{T}
    count::Int
end

OrderedBallot(ranking::Vector{T}) where {T} = OrderedBallot(ranking, 1)

weight(b::OrderedBallot) = b.count
reweight(b::OrderedBallot, newcount::Int) =
    OrderedBallot(b.ranking, newcount)

ranking(b::OrderedBallot) = b.ranking

allcandidates(b::OrderedBallot) = b.ranking

function indexballot(b::OrderedBallot{T}, candidates::Vector{T}) where {T}
    indices = indexin(b.ranking, candidates)
    all(!isnothing, indices) ||
        throw(ArgumentError(lazy"Choices $(b.ranking[isnothing.(indices)]) do not exist in the candidate list"))
    OrderedBallot(Vector{Int}(indices), weight(b))
end

const RunoffOrderedBallot = Tuple{Int, OrderedBallot}

Base.convert(::Type{PluralityBallot}, ballot::StrictlyRankedBallot) =
    PluralityBallot(first(ranking(ballot)), weight(ballot))

function preferencematrix(ballots::Vector{<:StrictlyRankedBallot{Int}}, implyunstated::Bool=true)
    ncands = maximum(maximum ∘ ranking, ballots)
    prefmat = zeros(Int, ncands, ncands)
    for ballot in ballots
        for i in 1:length(ballot.ranking), j in 1:i-1
            vi, vj = ranking(ballot)[i], ranking(ballot)[j]
            prefmat[vj, vi] += weight(ballot)
            prefmat[vi, vj] -= weight(ballot)
        end
        if implyunstated && length(ballot.ranking) < size(prefmat, 1)
            unstated = setdiff(axes(prefmat, 1), ballot.ranking)
            for r in ranking(ballot), u in unstated
                prefmat[r, u] += weight(ballot)
                prefmat[u, r] -= weight(ballot)
            end
        end
    end
    prefmat
end

function preferencematrix(ballots::Vector{<:StrictlyRankedBallot{T}}, allcands::Vector{T}, implyunstated::Bool=true) where {T}
    iballots = indexballot.(ballots, Ref(allcands))
    preferencematrix(iballots, implyunstated)
end

# ------------------
# Sum Ballot
# ------------------

struct SumBallot{T} <: RankedBallot{T}
    choices::Vector{Pair{T, Int}}
    count::Int
end

SumBallot(choices::Vector{Pair{T, Int}}) where {T} = SumBallot(choices, 1)

weight(b::SumBallot) = b.count
reweight(b::SumBallot, newcount::Int) =
    SumBallot(b.choices, newcount)

allcandidates(ballots::Vector{SumBallot}) =
    mapreduce(b -> keys(b.choices), union, ballots) |> collect |> sort

Base.convert(::Type{SumBallot}, ballot::ApprovalBallot) =
    SumBallot([c => 1 for c in ballot.choices], weight(ballot))
