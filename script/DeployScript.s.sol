// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/QIEVault.sol";
import "../src/QIEIdentity.sol";
import "../src/QIENeobank.sol";
import "../src/CreditScore.sol";
import "../src/QIELending.sol";

contract DeployScript is Script {
    function run() external {
        // Mainnet QUSDC
        address qusdc = 0x3F43DA82eC9A4f5285F10FaF1F26EcA7319E5DA5;

        // Protocol treasury - CHANGE TO GNOSIS SAFE FOR MAINNET
        address protocolTreasury = msg.sender;

        vm.startBroadcast();

        // 1. Deploy Vault first (no dependencies)
        QIEVault vault = new QIEVault(IERC20(qusdc));
        console.log("QIEVault deployed at:", address(vault));

        // 2. Deploy Identity (no dependencies)
        QIEIdentity identity = new QIEIdentity();
        console.log("QIEIdentity deployed at:", address(identity));

        // 3. Deploy Lending with temporary zero addresses
        QIELending lending = new QIELending(
            qusdc,
            address(vault),
            address(0), // scorer - will update after CreditScore deployment
            address(0), // neobank - will update after Neobank deployment
            protocolTreasury
        );
        console.log("QIELending deployed at:", address(lending));

        // 4. Deploy CreditScore (needs lending address)
        CreditScore scorer = new CreditScore(address(vault), address(lending));
        console.log("CreditScore deployed at:", address(scorer));

        // 5. Deploy Neobank (needs all other contracts)
        QIENeobank neobank = new QIENeobank(qusdc, address(vault), address(scorer), address(identity));
        console.log("QIENeobank deployed at:", address(neobank));

        // --- Wire contracts post-deployment ---

        // Update Lending with CreditScore address
        lending.setCreditScore(address(scorer));

        // Update Lending with Neobank address
        lending.setNeobank(address(neobank));

        // Connect Neobank to Lending
        neobank.setLending(address(lending));

        // Authorize Lending to deposit interest into Vault
        vault.setLendingContract(address(lending)); // ADD THIS

        // Authorize Neobank to issue identities
        identity.authorizeVerifier(address(neobank), true);

        vm.stopBroadcast();

        // Final summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("QUSDC:         ", qusdc);
        console.log("QIEVault:      ", address(vault));
        console.log("QIEIdentity:   ", address(identity));
        console.log("QIELending:    ", address(lending));
        console.log("CreditScore:   ", address(scorer));
        console.log("QIENeobank:    ", address(neobank));
        console.log("Treasury:      ", protocolTreasury);
    }
}
