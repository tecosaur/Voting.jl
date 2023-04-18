using Voting
using Test

ranked_1 = vcat(
    fill(OrderedBallot([1,2,4,3]), 7),
    fill(OrderedBallot([1,3,2,4]), 2),
    fill(OrderedBallot([2,3,4,1]), 4),
    fill(OrderedBallot([2,4,1,3]), 5),
    fill(OrderedBallot([3,1,2,4]), 1),
    fill(OrderedBallot([3,4,1,2]), 8))

ranked_2 = vcat(
    fill(OrderedBallot([1,2,4,3]), 42),
    fill(OrderedBallot([2,4,3,1]), 26),
    fill(OrderedBallot([4,3,2,1]), 15),
    fill(OrderedBallot([3,4,2,1]), 17))

ranked_2w = [
    OrderedBallotBundle([1,2,4,3], 42),
    OrderedBallotBundle([2,4,3,1], 26),
    OrderedBallotBundle([4,3,2,1], 15),
    OrderedBallotBundle([3,4,2,1], 17)]

@testset "Plurality" begin
    @test score(Plurality(), convert.(PluralityBallot, ranked_2)) ==
        Voting.CountSingleResult(Plurality(), 1, [1 => 42, 2 => 26, 3 => 17, 4 => 15])
end

@testset "Approval" begin
end

@testset "Borda" begin
    @test score(Borda(), ranked_1) ==
        Voting.CountSingleResult(Borda(), 2, [2 => 44, 1 => 42, 3 => 39, 4 => 37])
end

@testset "InstantRunoff" begin
    @test score(InstantRunoff(), ranked_2) ==
        Voting.InstantRunoffResult([3 => 58, 1 => 42], 2, 0)
end

@testset "STAR" begin
end

@testset "RankedPairs" begin
    @test score(RankedPairs(), ranked_1) ==
        Voting.RankedPairsResult(1, [(2 => 4, 11), (1 => 2, 9), (4 => 1, 7), (2 => 3, 5), (3 => 4, 3), (1 => 3, 1)])
    @test score(RankedPairs(), ranked_2) ==
        Voting.RankedPairsResult(2, [(4 => 3, 66), (2 => 3, 36), (2 => 4, 36), (2 => 1, 16), (3 => 1, 16), (4 => 1, 16)])
end
