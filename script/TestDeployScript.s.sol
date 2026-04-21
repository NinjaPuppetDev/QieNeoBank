// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/QIEVault.sol";
import "../src/QIEIdentity.sol";
import "../src/QIENeobank.sol";
import "../src/CreditScore.sol";
import "../src/QIELending.sol";
import "../src/interfaces/IQIEInterfaces.sol";

// Minimal mocks for local testing
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock QUSDC", "QUSDC") {
        _mint(msg.sender, 1_000_000e6);
    }
}

contract TestDeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy mock QUSDC if not provided
        address qusdc = vm.envOr("QUSDC_ADDRESS", address(0));
        if (qusdc == address(0)) {
            qusdc = address(new MockERC20());
            console.log("Deployed MockERC20 (QUSDC):", qusdc);
        }

        // --- Deploy core contracts ---

        // 1. Vault
        QIEVault vault = new QIEVault(IERC20(qusdc));
        console.log("QIEVault:      ", address(vault));

        // 2. Identity
        QIEIdentity identity = new QIEIdentity();
        console.log("QIEIdentity:   ", address(identity));

        // 3. Lending (deploy with temp addresses, update later)
        address protocolTreasury = msg.sender;
        QIELending lending = new QIELending(qusdc, address(vault), address(0), address(0), protocolTreasury);
        console.log("QIELending:    ", address(lending));

        // 4. Credit Score (uses lending for accuracy component)
        CreditScore scorer = new CreditScore(address(vault), address(lending));
        console.log("CreditScore:   ", address(scorer));

        // 5. Neobank (no prediction pool)
        QIENeobank neobank = new QIENeobank(qusdc, address(vault), address(scorer), address(identity));
        console.log("QIENeobank:    ", address(neobank));

        // --- Wire contracts ---

        // Update lending with correct addresses
        lending.setNeobank(address(neobank));
        lending.setCreditScore(address(scorer));

        // Set lending in neobank
        neobank.setLending(address(lending));

        // Authorize Lending to deposit interest into Vault
        vault.setLendingContract(address(lending)); // ADD THIS

        // Authorize neobank for identity operations
        identity.authorizeVerifier(address(neobank), true);

        vm.stopBroadcast();
    }
}
