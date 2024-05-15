module Voting

using StyledStrings

export OrderedBallot, PluralityBallot, ApprovalBallot,
    OrderedBallotBundle
export elect, Plurality, Approval, Borda, InstantRunoff,
    STAR, RankedPairs, Copeland

abstract type VotingMethod end

include("ballots.jl")
include("results.jl")
include("countresult.jl")

include("methods/plurality.jl")
include("methods/approval.jl")
include("methods/borda.jl")
include("methods/instantrunoff.jl")
include("methods/star.jl")
include("methods/rankedpairs.jl")
include("methods/copeland.jl")

include("properties.jl")

end
