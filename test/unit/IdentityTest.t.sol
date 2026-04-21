// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/QIEIdentity.sol";

contract QIEIdentityTest is Test {
    QIEIdentity public identity;

    address owner     = address(1);
    address verifier  = address(2);
    address user      = address(3);
    address user2     = address(4);

    // Test data
    bytes32 biometricHash = keccak256("face_scan_123");
    bytes32 documentHash  = keccak256("passport_abc");
    bytes32 livenessProof = keccak256("liveness_xyz");
    uint256 constant BRAZIL_CODE    = 76;
    uint256 constant VALIDITY_DAYS  = 365;

    function setUp() public {
        vm.prank(owner);
        identity = new QIEIdentity();

        vm.prank(owner);
        identity.authorizeVerifier(verifier, true);
    }

    // ==================== IDENTITY ISSUANCE ====================

    function test_IssueIdentity_BasicTier() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        assertTrue(identity.isVerified(user), "User should be verified");
        assertEq(uint256(identity.getTier(user)), uint256(QIEIdentity.Tier.Basic), "Tier should be Basic");

        (
            QIEIdentity.Tier tier,
            uint256 issuedAt,
            uint256 expiresAt,
            uint256 countryCode,
            bool isActive,
            bool canAccessLending
        ) = identity.getIdentity(user);

        assertEq(uint256(tier), uint256(QIEIdentity.Tier.Basic));
        assertEq(countryCode, BRAZIL_CODE);
        assertTrue(isActive);
        assertFalse(canAccessLending); // Basic cannot access lending
        assertGt(expiresAt, issuedAt);
    }

    function test_IssueIdentity_VerifiedTier() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Verified, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        assertEq(uint256(identity.getTier(user)), uint256(QIEIdentity.Tier.Verified));

        (,,,,, bool canAccessLending) = identity.getIdentity(user);
        assertTrue(canAccessLending, "Verified tier should access lending");
    }

    function test_IssueIdentity_RevertIfAlreadyHasIdentity() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        vm.prank(verifier);
        vm.expectRevert(QIEIdentity.AlreadyHasIdentity.selector);
        identity.issueIdentity(
            user,
            QIEIdentity.Tier.Basic,
            keccak256("different_biometric"),
            keccak256("different_doc"),
            keccak256("different_liveness"),
            BRAZIL_CODE,
            VALIDITY_DAYS
        );
    }

    function test_IssueIdentity_RevertIfDuplicateBiometric() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        // Sybil attack: same biometric, different wallet
        vm.prank(verifier);
        vm.expectRevert(QIEIdentity.BiometricMismatch.selector);
        identity.issueIdentity(
            user2,
            QIEIdentity.Tier.Basic,
            biometricHash, // same biometric
            keccak256("different_doc"),
            keccak256("different_liveness"),
            BRAZIL_CODE,
            VALIDITY_DAYS
        );
    }

    function test_IssueIdentity_RevertIfDuplicateDocument() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        // Same document hash, different biometric — should also be blocked (v2)
        vm.prank(verifier);
        vm.expectRevert(QIEIdentity.DocumentAlreadyUsed.selector);
        identity.issueIdentity(
            user2,
            QIEIdentity.Tier.Basic,
            keccak256("different_biometric"),
            documentHash, // same document
            keccak256("different_liveness"),
            BRAZIL_CODE,
            VALIDITY_DAYS
        );
    }

    function test_IssueIdentity_RevertIfUnsupportedCountry() public {
        vm.prank(verifier);
        vm.expectRevert(QIEIdentity.CountryNotSupported.selector);
        identity.issueIdentity(
            user,
            QIEIdentity.Tier.Basic,
            biometricHash,
            documentHash,
            livenessProof,
            999, // unsupported
            VALIDITY_DAYS
        );
    }

    function test_IssueIdentity_RevertIfUnauthorizedVerifier() public {
        address unauthorized = address(99);

        vm.prank(unauthorized);
        vm.expectRevert(QIEIdentity.UnauthorizedVerifier.selector);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );
    }

    // ==================== TIER UPGRADES ====================

    function test_UpgradeTier() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        vm.prank(verifier);
        identity.upgradeTier(user, QIEIdentity.Tier.Verified, keccak256("new_liveness"), 180);

        assertEq(uint256(identity.getTier(user)), uint256(QIEIdentity.Tier.Verified));

        (,, uint256 expiresAt,,,) = identity.getIdentity(user);
        assertGt(expiresAt, block.timestamp + 365 days);
    }

    function test_UpgradeTier_RevertIfLowerTier() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Verified, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        vm.prank(verifier);
        vm.expectRevert(QIEIdentity.InvalidTier.selector);
        identity.upgradeTier(user, QIEIdentity.Tier.Basic, keccak256("new_liveness"), 180);
    }

    // ==================== IDENTITY REVOCATION ====================

    function test_RevokeIdentity() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        assertTrue(identity.isVerified(user));

        vm.prank(verifier);
        identity.revokeIdentity(user, "Fraud detected");

        assertFalse(identity.isVerified(user));
        assertEq(uint256(identity.getTier(user)), uint256(QIEIdentity.Tier.None));
        assertEq(identity.passportId(user), 0);
    }

    function test_RevokeIdentity_CooldownPersistsAcrossRevocation() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        vm.prank(verifier);
        identity.revokeIdentity(user, "Test revocation");

        // biometricLastRevoked should be set even though Identity struct is cleared
        uint256 remaining = identity.cooldownRemaining(biometricHash);
        assertGt(remaining, 0, "Cooldown should be active after revocation");
    }

    function test_RevokeIdentity_BlocksReissueBeforeCooldown() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        vm.prank(verifier);
        identity.revokeIdentity(user, "Test revocation");

        // Try to re-issue immediately — should fail with RevocationCooldown
        vm.prank(verifier);
        vm.expectRevert(QIEIdentity.RevocationCooldown.selector);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, keccak256("new_doc"), keccak256("new_liveness"), BRAZIL_CODE, VALIDITY_DAYS
        );
    }

    function test_ReinstateIdentity_AfterCooldown() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        vm.prank(verifier);
        identity.revokeIdentity(user, "Test revocation");

        vm.warp(block.timestamp + 91 days);

        bytes32 newBiometric = keccak256("new_face_scan");
        vm.prank(owner);
        identity.reinstateIdentity(
            user,
            QIEIdentity.Tier.Verified,
            newBiometric,
            keccak256("new_doc"),
            keccak256("new_liveness"),
            BRAZIL_CODE,
            VALIDITY_DAYS
        );

        assertTrue(identity.isVerified(user));
        assertEq(uint256(identity.getTier(user)), uint256(QIEIdentity.Tier.Verified));
    }

    function test_ReinstateIdentity_PreservesCanonicalPassportId() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        uint256 originalCanonicalId = identity.canonicalPassportId(biometricHash);
        assertGt(originalCanonicalId, 0, "Canonical ID should be assigned on first issuance");

        vm.prank(verifier);
        identity.revokeIdentity(user, "Test revocation");

        vm.warp(block.timestamp + 91 days);

        vm.prank(owner);
        identity.reinstateIdentity(
            user,
            QIEIdentity.Tier.Verified,
            biometricHash,        // same biometric — should reclaim same canonical ID
            keccak256("new_doc"),
            keccak256("new_liveness"),
            BRAZIL_CODE,
            VALIDITY_DAYS
        );

        assertEq(
            identity.canonicalPassportId(biometricHash),
            originalCanonicalId,
            "Canonical passport ID must be preserved after reinstatement"
        );
        assertEq(identity.passportId(user), originalCanonicalId, "passportId should match canonical ID");
    }

    // ==================== ACCESS CONTROL ====================

    function test_IsVerifiedWithTier() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Verified, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        assertTrue(identity.isVerifiedWithTier(user, QIEIdentity.Tier.Basic));
        assertTrue(identity.isVerifiedWithTier(user, QIEIdentity.Tier.Verified));
        assertFalse(identity.isVerifiedWithTier(user, QIEIdentity.Tier.Enhanced));
        assertFalse(identity.isVerifiedWithTier(user, QIEIdentity.Tier.Institutional));
    }

    function test_GetMaxUnsecuredLimit() public {
        // Basic — no unsecured lending
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );
        assertEq(identity.getMaxUnsecuredLimit(user), 0);

        // Verified — $500
        address userVerified = address(10);
        vm.prank(verifier);
        identity.issueIdentity(
            userVerified,
            QIEIdentity.Tier.Verified,
            keccak256("bio_verified"),
            keccak256("doc_verified"),
            keccak256("live_verified"),
            BRAZIL_CODE,
            VALIDITY_DAYS
        );
        assertEq(identity.getMaxUnsecuredLimit(userVerified), 500e6);

        // Enhanced — $5k
        address userEnhanced = address(11);
        vm.prank(verifier);
        identity.issueIdentity(
            userEnhanced,
            QIEIdentity.Tier.Enhanced,
            keccak256("bio_enhanced"),
            keccak256("doc_enhanced"),
            keccak256("live_enhanced"),
            BRAZIL_CODE,
            VALIDITY_DAYS
        );
        assertEq(identity.getMaxUnsecuredLimit(userEnhanced), 5000e6);
    }

    function test_CheckLendingAccess() public {
        // Basic — no lending
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );
        assertFalse(identity.checkLendingAccess(user));

        // Verified — lending allowed
        address userVerified = address(10);
        vm.prank(verifier);
        identity.issueIdentity(
            userVerified,
            QIEIdentity.Tier.Verified,
            keccak256("bio_verified"),
            keccak256("doc_verified"),
            keccak256("live_verified"),
            BRAZIL_CODE,
            VALIDITY_DAYS
        );
        assertTrue(identity.checkLendingAccess(userVerified));
    }

    // ==================== EXPIRATION ====================

    function test_IdentityExpiration() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user,
            QIEIdentity.Tier.Basic,
            biometricHash,
            documentHash,
            livenessProof,
            BRAZIL_CODE,
            30 // 30-day validity
        );

        assertTrue(identity.isVerified(user));
        assertFalse(identity.isExpired(user));

        vm.warp(block.timestamp + 31 days);

        assertTrue(identity.isExpired(user));
        assertFalse(identity.isVerified(user));
        assertEq(uint256(identity.getTier(user)), uint256(QIEIdentity.Tier.None));
    }

    // ==================== FREEZING ====================

    function test_FreezeIdentity() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Verified, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        assertTrue(identity.isVerified(user));

        vm.prank(owner);
        identity.freezeIdentity(user);

        assertFalse(identity.isVerified(user));
        assertEq(uint256(identity.getTier(user)), uint256(QIEIdentity.Tier.None));
    }

    function test_UnfreezeIdentity() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Verified, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        vm.prank(owner);
        identity.freezeIdentity(user);
        assertFalse(identity.isVerified(user));

        vm.prank(owner);
        identity.unfreezeIdentity(user);
        assertTrue(identity.isVerified(user));
    }

    // ==================== SOULBOUND ENFORCEMENT ====================

    function test_CannotTransferIdentity() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        uint256 tokenId = identity.passportId(user);

        vm.prank(user);
        vm.expectRevert("QIEIdentity: non-transferable");
        identity.transferFrom(user, user2, tokenId);
    }

    function test_CannotApproveIdentity() public {
        vm.prank(verifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        uint256 tokenId = identity.passportId(user);

        vm.prank(user);
        vm.expectRevert("QIEIdentity: non-transferable");
        identity.approve(user2, tokenId);
    }

    // ==================== COUNTRY SUPPORT ====================

    function test_AddNewCountry() public {
        uint256 newCountry = 999;
        assertFalse(identity.supportedCountries(newCountry));

        vm.prank(owner);
        identity.setCountrySupport(newCountry, true, "Test Country");

        assertTrue(identity.supportedCountries(newCountry));
    }

    function test_AllLatAmCountriesSupported() public {
        assertTrue(identity.supportedCountries(32));  // Argentina
        assertTrue(identity.supportedCountries(76));  // Brazil
        assertTrue(identity.supportedCountries(484)); // Mexico
        assertTrue(identity.supportedCountries(170)); // Colombia
        assertTrue(identity.supportedCountries(604)); // Peru
        assertTrue(identity.supportedCountries(152)); // Chile
        assertTrue(identity.supportedCountries(320)); // Guatemala
    }

    // ==================== ADMIN FUNCTIONS ====================

    function test_AuthorizeVerifier() public {
        address newVerifier = address(20);

        assertFalse(identity.authorizedVerifiers(newVerifier));

        vm.prank(owner);
        identity.authorizeVerifier(newVerifier, true);

        assertTrue(identity.authorizedVerifiers(newVerifier));

        vm.prank(newVerifier);
        identity.issueIdentity(
            user, QIEIdentity.Tier.Basic, biometricHash, documentHash, livenessProof, BRAZIL_CODE, VALIDITY_DAYS
        );

        assertTrue(identity.isVerified(user));
    }

    function test_SetTierRequirements() public {
        vm.prank(owner);
        identity.setTierRequirements(
            QIEIdentity.Tier.Verified,
            100e6,  // $100 min deposit
            1000e6, // $1000 max unsecured
            false   // no lending access
        );

        assertEq(identity.minDepositAmount(QIEIdentity.Tier.Verified), 100e6);
        assertEq(identity.maxUnsecuredLimit(QIEIdentity.Tier.Verified), 1000e6);
        assertFalse(identity.tierCanAccessLending(QIEIdentity.Tier.Verified));
    }
}