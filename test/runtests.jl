using Voting
using Test

ranked_1 = [
    OrderedBallot([1, 2, 4, 3], 7),
    OrderedBallot([1, 3, 2, 4], 2),
    OrderedBallot([2, 3, 4, 1], 4),
    OrderedBallot([2, 4, 1, 3], 5),
    OrderedBallot([3, 1, 2, 4], 1),
    OrderedBallot([3, 4, 1, 2], 8)]

ranked_2 = [
    OrderedBallot([:memphis,     :nashville,   :chattanooga, :knoxville], 42),
    OrderedBallot([:nashville,   :chattanooga, :knoxville,   :memphis],   26),
    OrderedBallot([:chattanooga, :knoxville,   :nashville,   :memphis],   15),
    OrderedBallot([:knoxville,   :chattanooga, :nashville,   :memphis],   17)]

@testset "Plurality" begin
    @test score(Plurality(), convert.(PluralityBallot, ranked_2)) ==
        Voting.CountMultiResult(
            Plurality(), [:memphis, :nashville, :knoxville, :chattanooga],
            [:memphis => 42, :nashville => 26, :knoxville => 17, :chattanooga => 15])
end

@testset "Approval" begin
end

@testset "Borda" begin
    @test score(Borda(), ranked_1) ==
        Voting.CountMultiResult(
            Borda(), [2, 1, 3, 4],
            [2 => 44, 1 => 42, 3 => 39, 4 => 37])
end

@testset "InstantRunoff" begin
    @test score(InstantRunoff(), ranked_2) ==
        Voting.InstantRunoffResult(
            [:knoxville => 58, :memphis => 42], 2, 0)
end

@testset "STAR" begin
end

@testset "RankedPairs" begin
    @test score(RankedPairs(), ranked_1) ==
        Voting.RankedPairsResult(1,
                                 [(2 => 4, 11),
                                  (1 => 2, 9),
                                  (4 => 1, 7),
                                  (2 => 3, 5),
                                  (3 => 4, 3),
                                  (1 => 3, 1)])
    @test score(RankedPairs(), ranked_2) ==
        Voting.RankedPairsResult(:nashville,
                                 [(:chattanooga => :knoxville, 66),
                                  (:nashville => :chattanooga, 36),
                                  (:nashville => :knoxville, 36),
                                  (:nashville => :memphis, 16),
                                  (:chattanooga => :memphis, 16),
                                  (:knoxville => :memphis, 16)])
end
