// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

contract Tontine {
    uint256 startsAt;
    mapping(address => uint256) public checkins;
    address[] public participants;

    constructor(uint256 startsAt_) {
        startsAt = startsAt_;
    }

    function join() public payable {
        require(msg.value == 10 ether, "Must pay");
        require(checkins[msg.sender] == 0, "Already joined");

        checkins[msg.sender] = 1;
        participants.push(msg.sender);
    }

    function currentDay() public view returns (uint256) {
        if (startsAt > block.timestamp) {
            // Not started yet
            return 0;
        }

        uint256 delta = block.timestamp - startsAt;
        return delta / 1 days + 1;
    }

    function checkIn() public {
        uint256 today = currentDay();
        uint256 counter = checkins[msg.sender];

        require(today > 0, "Not started yet");
        require(counter != today, "Already checked in");
        unchecked {
            // today - 1 can't underflow
            require(counter == today - 1, "Missed previous checkin");
        }

        checkins[msg.sender] += 1;
    }

    function claim() public payable {
        uint256 today = currentDay();
        require(today > 2, "Should wait at least 2 days");
        require(checkins[msg.sender] == today, "Have not checked in today");
        for (uint256 i = 0; i < participants.length; i++) {
            if (msg.sender != participants[i]) {
                unchecked {
                    // today - 2 can't underflow
                    require(
                        checkins[participants[i]] <= today - 2,
                        "Everyone else should be dead"
                    );
                }
            }
        }

        selfdestruct(payable(msg.sender));
    }
}
