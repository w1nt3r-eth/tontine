// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "lib/ds-test/src/test.sol";
import "lib/vm.sol";
import "src/Tontine.sol";

contract TontineTest is DSTest {
    Vm vm = Vm(HEVM_ADDRESS);
    Tontine tontine;

    function setUp() public {
        tontine = new Tontine(10000000);
    }

    function testJoin() public {
        tontine.join{value: 10 ether}();
        assertEq(tontine.checkins(address(this)), 1);
    }

    function testFail_cantJoinTwice() public {
        tontine.join{value: 10 ether}();
        tontine.join{value: 10 ether}();
    }

    function testDays() public {
        assertEq(tontine.currentDay(), 0);
        vm.warp(10000000 + 1);
        assertEq(tontine.currentDay(), 1);
        vm.warp(10000000 + 1 days + 1);
        assertEq(tontine.currentDay(), 2);
    }

    function testFail_checkinBeforeStart() public {
        tontine.join{value: 10 ether}();
        tontine.checkIn();
    }

    function test_checkin() public {
        tontine.join{value: 10 ether}();
        vm.warp(10000000 + 1 days + 1);
        tontine.checkIn();
    }

    function testFail_missedCheckin() public {
        tontine.join{value: 10 ether}();
        vm.warp(10000000 + 2 days + 1);
        tontine.checkIn();
    }

    function test_claim() public {
        AnotherPlayer player = new AnotherPlayer(tontine);
        payable(address(player)).transfer(10 ether);
        player.join();

        tontine.join{value: 10 ether}();
        vm.warp(10000000 + 1 days + 1);
        tontine.checkIn();
        vm.warp(10000000 + 2 days + 1);
        tontine.checkIn();

        uint256 preBalance = address(this).balance;
        tontine.claim();
        uint256 postBalance = address(this).balance;
        assertEq(preBalance + 20 ether, postBalance);
    }

    receive() external payable {}
}

contract AnotherPlayer {
    Tontine tontine;

    constructor(Tontine tontine_) {
        tontine = tontine_;
    }

    function join() public {
        tontine.join{value: 10 ether}();
    }

    function checkIn() public {
        tontine.checkIn();
    }

    receive() external payable {}
}
