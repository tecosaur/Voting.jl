abstract type Ballot end

struct BallotContext{B <: Ballot, C}
    ballot::B
    candidates::Vector{C}
end

abstract type UnrankedBallot <: Ballot end

struct ApprovalBallot <: UnrankedBallot
    choices::Set{Int}
end

function ApprovalBallot(choices::Vector{T}, candidates::Vector{T}) where {T}
    indices = indexin(choices, candidates)
    all(!isnothing, indices) ||
        error("Choices $(choices[isnothing.(indices)]) do not exist in the candidate list")
    ApprovalBallot(Set(indices))
end

allcandidates(ballots::Vector{ApprovalBallot}) =
    mapreduce(b -> b.choices, union, ballots) |> collect |> sort

struct PluralityBallot <: UnrankedBallot
    choice::Int
end

function PluralityBallot(choice::T, candidates::Vector{T}) where {T}
    index = findfirst(==(choice), candidates)
    isnothing(index) || error("Choice $(sprint(show, choice)) did not exist in candidate list")
    PluralityBallot(index)
end

abstract type RankedBallot <: Ballot end

struct ScoredBallot <: RankedBallot
    scores::Dict{Int, Int}
end

allcandidates(ballots::Vector{ScoredBallot}) =
    Iterators.flatten((keys(b.scores) for b in ballots)) |> unique |> sort

abstract type StrictlyRankedBallot <: Ballot end

struct OrderedBallot <: StrictlyRankedBallot
    ranking::Vector{Int}
end

function OrderedBallot(ranking::Vector{T}, candidates::Vector{T}) where {T}
    indices = indexin(ranking, candidates)
    all(!isnothing, indices) ||
        error("Choices $(ranking[isnothing.(indices)]) do not exist in the candidate list")
    OrderedBallot(indices)
end

allcandidates(ballots::Vector{OrderedBallot}) =
    Iterators.flatten((b.ranking for b in ballots)) |> unique |> sort

const RunoffOrderedBallot = Tuple{Int, OrderedBallot}

Base.convert(::Type{PluralityBallot}, ballot::OrderedBallot) =
    PluralityBallot(first(ballot.ranking))

function preferencematrix(ballots::Vector{OrderedBallot})
    allcands = allcandidates(ballots)
    prefmat = zeros(Int, maximum(allcands), maximum(allcands))
    for ballot in ballots, i in 1:length(ballot.ranking), j in 1:i-1
        vi, vj = ballot.ranking[i], ballot.ranking[j]
        prefmat[vj, vi] += 1
        prefmat[vi, vj] -= 1
    end
    prefmat
end

struct SumBallot <: RankedBallot
    choices::Vector{Pair{Int, Int}}
end

Base.convert(::Type{SumBallot}, ballot::ApprovalBallot) =
    SumBallot([c => 1 for c in ballot.choices])

allcandidates(ballots::Vector{SumBallot}) =
    mapreduce(b -> keys(b.choices), union, ballots) |> collect |> sort
