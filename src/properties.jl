"""
    ismonotonic(voting_system::Type{<:VotingMethod})

Returns `true` if under the `voting_system` if it is not possible to prevent a
candidate from being elected by *raising* their ranking on a ballot, nor
possible to elect an otherwise unelected candidate by *lowering* their ranking
on a ballot. Returns `false` otherwise.

See https://en.wikipedia.org/wiki/Monotonicity_criterion.
"""
function ismonotonic end

ismonotonic(::Type{Plurality}) = true
ismonotonic(::Type{Approval}) = true
ismonotonic(::Type{Borda}) = true
ismonotonic(::Type{InstantRunoff}) = false
ismonotonic(::Type{STAR}) = true
ismonotonic(::Type{RankedPairs}) = true

"""
    hascondorcetwinner(voting_system::Type{<:VotingMethod})

Returns `true` if the `voting_system` always picks the Condorcet winner when one
exists. Returns `false` otherwise.

See https://en.wikipedia.org/wiki/Condorcet_winner_criterion.
"""
function hascondorcetwinner end

hascondorcetwinner(::Type{Plurality}) = false
hascondorcetwinner(::Type{Approval}) = false
hascondorcetwinner(::Type{Borda}) = false
hascondorcetwinner(::Type{InstantRunoff}) = false
hascondorcetwinner(::Type{STAR}) = false
hascondorcetwinner(::Type{RankedPairs}) = true

"""
    hascondorcetloser(voting_system::Type{<:VotingMethod})

Returns `true` if the `voting_system` never picks the Condorcet loser when one
exists. Returns `false` otherwise.

See https://en.wikipedia.org/wiki/Condorcet_loser_criterion.
"""
function hascondorcetloser end

hascondorcetloser(::Type{Plurality}) = false
hascondorcetloser(::Type{Approval}) = false
hascondorcetloser(::Type{Borda}) = true
hascondorcetloser(::Type{InstantRunoff}) = true
hascondorcetloser(::Type{STAR}) = true
hascondorcetloser(::Type{RankedPairs}) = true

"""
    hasmajority(voting_system::Type{<:VotingMethod})

Returns `true` when under `voting_system` if a candidate is ranked first by a a
majority, the candidate must win. Returns `false` otherwise.

See https://en.wikipedia.org/wiki/Majority_criterion.
"""
function hasmajority end

hasmajority(::Type{Plurality}) = true
hasmajority(::Type{Borda}) = false
hasmajority(::Type{InstantRunoff}) = true
hasmajority(::Type{STAR}) = false
hasmajority(::Type{RankedPairs}) = true

"""
    hasmajorityloser(voting_system::Type{<:VotingMethod})

Returns `true` when under `voting_system` if a candidate is ranked last by a a
majority, the candidate never wins. Returns `false` otherwise.

See https://en.wikipedia.org/wiki/Majority_criterion.
"""
function hasmajorityloser end

hasmajorityloser(::Type{Plurality}) = false
hasmajorityloser(::Type{Borda}) = true
hasmajorityloser(::Type{InstantRunoff}) = true
hasmajorityloser(::Type{STAR}) = false
hasmajorityloser(::Type{RankedPairs}) = true

"""
    hasmutualmajority(voting_system::Type{<:VotingMethod})

Returns `true` if when under `voting_system` if there is a subset of candidates
that are strictly preferred to all other candidates by a majority, the winner
must come from that subset. Returns `false` otherwise.

See https://en.wikipedia.org/wiki/Mutual_majority_criterion.
"""
function hasmutualmajority end

hasmutualmajority(::Type{Plurality}) = false
hasmutualmajority(::Type{Borda}) = true
hasmutualmajority(::Type{InstantRunoff}) = true
hasmutualmajority(::Type{STAR}) = true
hasmutualmajority(::Type{RankedPairs}) = true

"""
    isindependntofclones(voting_system::Type{<:VotingMethod})

Returns `true` if the `voting_system` is robust to strategic nomination, in the
sense that the winner should not change with the addition of a similar candidate
to to an existing candidate.
"""
function isindependntofclones end

isindependntofclones(::Type{Plurality}) = false
isindependntofclones(::Type{Borda}) = false
isindependntofclones(::Type{InstantRunoff}) = true
isindependntofclones(::Type{STAR}) = false
isindependntofclones(::Type{RankedPairs}) = true
