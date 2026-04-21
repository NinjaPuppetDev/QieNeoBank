// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title QIEIdentity
 * @notice Soulbound identity passport for QIE Neobank
 * @dev Non-transferable ERC721 with tiered KYC levels and QIE Pass integration.
 *
 * CHANGES vs v1 (all backwards-compatible):
 *
 *  1. CANONICAL PASSPORT IDs
 *     Each unique biometric hash receives a permanent canonical passport ID on
 *     first issuance. Revocation and reinstatement REUSE that same ID instead of
 *     minting a fresh token. This means bad-debt history in CreditScore/QIEBadDebt
 *     survives wallet rotation and revocation cycles.
 *     New storage: `canonicalPassportId`, `biometricToCanonical`.
 *
 *  2. BIOMETRIC COOLDOWN PERSISTED ACROSS REVOCATION
 *     `lastRevoked` was stored on the Identity struct, which is cleared on
 *     revocation. It is now also mirrored to `biometricLastRevoked` (keyed by
 *     biometricHash) so the 90-day cooldown is actually enforced when the user
 *     tries to re-register.
 *     New storage: `biometricLastRevoked`.
 *     New error: `RevocationCooldown` (was defined but never reachable before).
 *
 *  3. DOCUMENT UNIQUENESS
 *     `documentHash` is now tracked in `usedDocuments` the same way
 *     `biometricHash` is tracked in `usedBiometrics`. Prevents the same
 *     government ID being reused across wallets even when a different selfie
 *     is supplied.
 *     New storage: `usedDocuments`.
 *     New error: `DocumentAlreadyUsed`.
 *
 * All existing public state variables, events, errors, and function signatures
 * are preserved so downstream tests require no changes.
 */
contract QIEIdentity is ERC721, Ownable2Step {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // ── Custom errors ──────────────────────────────────────────
    error AlreadyHasIdentity();
    error IdentityNotFound();
    error InvalidTier();
    error TierTooLow();
    error IdentityFrozen();
    error UnauthorizedVerifier();
    error BiometricMismatch();
    error DocumentExpired();
    error CountryNotSupported();
    error RevocationCooldown();
    error InvalidQIESignature();
    error QIEAttestationExpired();
    /// @dev NEW — documentHash already registered to another passport.
    error DocumentAlreadyUsed();

    // ── Enums ──────────────────────────────────────────────────
    enum Tier {
        None, // 0 - No identity, no access
        Basic, // 1 - Email/phone verified (deposit only, no lending)
        Verified, // 2 - Gov ID + selfie (collateralized lending)
        Enhanced, // 3 - Proof of address + liveness + video (unsecured up to $5k)
        Institutional // 4 - Corporate verification (unsecured up to $100k)
    }

    // ── Structs ────────────────────────────────────────────────
    struct Identity {
        Tier tier;
        uint256 issuedAt;
        uint256 expiresAt;
        bytes32 biometricHash;
        bytes32 documentHash;
        bytes32 livenessProof;
        uint256 countryCode;
        bool frozen;
        uint256 lastRevoked;
    }

    /// @notice QIE Pass attestation structure for privacy-preserving verification
    struct QIEAttestation {
        bytes32 credentialHash;
        uint256 attestedAt;
        uint256 expiresAt;
        bytes32 claimsMerkleRoot;
        bool isValid;
    }

    // ── Original state (unchanged) ─────────────────────────────
    mapping(address => uint256) public passportId;
    mapping(uint256 => Identity) public identities;
    mapping(address => bool) public authorizedVerifiers;
    mapping(uint256 => bool) public supportedCountries;
    mapping(bytes32 => bool) public usedBiometrics;
    mapping(address => QIEAttestation) public qieAttestations;

    address public qiePassSigner;
    uint256 private _tokenIdCounter;
    uint256 public constant REVOCATION_COOLDOWN = 90 days;

    mapping(Tier => uint256) public minDepositAmount;
    mapping(Tier => uint256) public maxUnsecuredLimit;
    mapping(Tier => bool) public tierCanAccessLending;

    // ── NEW state ──────────────────────────────────────────────

    /**
     * @notice Maps a biometricHash to its permanent canonical passport ID.
     * @dev Assigned once on first issuance and never changes. Reinstatement
     *      reuses this ID so the token stays linked to the same credit history.
     */
    mapping(bytes32 => uint256) public canonicalPassportId;

    /**
     * @notice Records the block.timestamp of the most recent revocation for a
     *         biometric hash. Persists even after the Identity struct is deleted,
     *         enforcing the 90-day REVOCATION_COOLDOWN on re-registration.
     */
    mapping(bytes32 => uint256) public biometricLastRevoked;

    /**
     * @notice Tracks which documentHashes have been registered.
     * @dev Mirrors usedBiometrics but for government-issued document hashes.
     *      Freed (set to false) on revocation so the cooldown window enforced
     *      by biometricLastRevoked still guards against immediate reuse.
     */
    mapping(bytes32 => bool) public usedDocuments;

    // ── Events (all original events preserved) ────────────────
    event IdentityIssued(address indexed user, uint256 tokenId, Tier tier, uint256 countryCode, bytes32 biometricHash);
    event TierUpgraded(address indexed user, Tier newTier, uint256 previousTier);
    event IdentityRevoked(address indexed user, string reason, uint256 cooldownEnd);
    event IdentityReinstated(address indexed user);
    event VerifierAuthorized(address indexed verifier, bool authorized);
    event CountrySupportUpdated(uint256 countryCode, bool supported, string countryName);
    event QIEAttestationLinked(address indexed user, bytes32 credentialHash, uint256 expiresAt);
    event QIEAttestationRevoked(address indexed user, bytes32 credentialHash);
    event QiePassSignerUpdated(address indexed oldSigner, address indexed newSigner);

    // ── Constructor ────────────────────────────────────────────
    constructor() ERC721("QIE Identity Passport", "QIE-ID") Ownable(msg.sender) {
        minDepositAmount[Tier.Basic] = 1e6;
        minDepositAmount[Tier.Verified] = 10e6;
        minDepositAmount[Tier.Enhanced] = 100e6;
        minDepositAmount[Tier.Institutional] = 10000e6;

        maxUnsecuredLimit[Tier.Basic] = 0;
        maxUnsecuredLimit[Tier.Verified] = 500e6;
        maxUnsecuredLimit[Tier.Enhanced] = 5000e6;
        maxUnsecuredLimit[Tier.Institutional] = 100000e6;

        tierCanAccessLending[Tier.Basic] = false;
        tierCanAccessLending[Tier.Verified] = true;
        tierCanAccessLending[Tier.Enhanced] = true;
        tierCanAccessLending[Tier.Institutional] = true;

        _initializeCountries();
    }

    // ── Internal Helper Functions ──────────────────────────────

    function _processVerifiedClaims(address user, bytes32 claimsMerkleRoot) internal {
        Identity storage identity = identities[passportId[user]];
        if (identity.tier == Tier.Basic && _verifyEnhancedClaims(claimsMerkleRoot)) {
            _upgradeToTier(user, Tier.Verified);
        }
    }

    function _verifyEnhancedClaims(bytes32 claimsMerkleRoot) internal pure returns (bool) {
        return claimsMerkleRoot != bytes32(0);
    }

    function _upgradeToTier(address user, Tier newTier) internal {
        uint256 tokenId = passportId[user];
        Identity storage identity = identities[tokenId];
        Tier oldTier = identity.tier;
        identity.tier = newTier;
        emit TierUpgraded(user, newTier, uint256(oldTier));
    }

    function _isVerifiedWithMinTier(address user, Tier minTier) internal view returns (bool) {
        uint256 tokenId = passportId[user];
        if (tokenId == 0) return false;
        Identity storage identity = identities[tokenId];
        if (identity.frozen) return false;
        if (block.timestamp > identity.expiresAt) return false;
        if (uint256(identity.tier) < uint256(minTier)) return false;
        return true;
    }

    /**
     * @dev Resolves or mints a canonical passport ID for a biometricHash.
     *
     *      - If the biometricHash has been seen before, the existing canonical
     *        ID is returned. This is the key mechanism that links a reissued
     *        passport to its prior credit/bad-debt history.
     *
     *      - If the biometricHash is brand new, a fresh token ID is minted from
     *        `_tokenIdCounter` and permanently bound to the hash.
     */
    function _resolveCanonicalId(bytes32 biometricHash) internal returns (uint256 tokenId) {
        tokenId = canonicalPassportId[biometricHash];
        if (tokenId == 0) {
            tokenId = ++_tokenIdCounter;
            canonicalPassportId[biometricHash] = tokenId;
        }
    }

    /**
     * @dev Shared validation for issueIdentity and reinstateIdentity.
     *      Checks cooldown, country support, and both hash uniqueness guards.
     */
    function _validateNewIdentity(bytes32 biometricHash, bytes32 documentHash, uint256 countryCode) internal view {
        if (!supportedCountries[countryCode]) revert CountryNotSupported();

        // Enforce cooldown even after a revocation wipes the Identity struct.
        if (
            biometricLastRevoked[biometricHash] != 0
                && block.timestamp < biometricLastRevoked[biometricHash] + REVOCATION_COOLDOWN
        ) revert RevocationCooldown();

        if (usedBiometrics[biometricHash]) revert BiometricMismatch();
        if (usedDocuments[documentHash]) revert DocumentAlreadyUsed();
    }

    function _initializeCountries() internal {
        supportedCountries[32] = true; // Argentina
        supportedCountries[68] = true; // Bolivia
        supportedCountries[76] = true; // Brazil
        supportedCountries[152] = true; // Chile
        supportedCountries[170] = true; // Colombia
        supportedCountries[218] = true; // Ecuador
        supportedCountries[328] = true; // Guyana
        supportedCountries[600] = true; // Paraguay
        supportedCountries[604] = true; // Peru
        supportedCountries[740] = true; // Suriname
        supportedCountries[858] = true; // Uruguay
        supportedCountries[862] = true; // Venezuela
        supportedCountries[84] = true; // Belize
        supportedCountries[188] = true; // Costa Rica
        supportedCountries[222] = true; // El Salvador
        supportedCountries[320] = true; // Guatemala
        supportedCountries[340] = true; // Honduras
        supportedCountries[558] = true; // Nicaragua
        supportedCountries[591] = true; // Panama
        supportedCountries[124] = true; // Canada
        supportedCountries[484] = true; // Mexico
        supportedCountries[630] = true; // Puerto Rico
        supportedCountries[214] = true; // Dominican Republic
        supportedCountries[192] = true; // Cuba
        supportedCountries[388] = true; // Jamaica
        supportedCountries[780] = true; // Trinidad and Tobago
        supportedCountries[44] = true; // Bahamas
        supportedCountries[52] = true; // Barbados
        supportedCountries[308] = true; // Grenada
        supportedCountries[659] = true; // Saint Kitts and Nevis
        supportedCountries[662] = true; // Saint Lucia
        supportedCountries[670] = true; // Saint Vincent and the Grenadines
        supportedCountries[28] = true; // Antigua and Barbuda
        supportedCountries[212] = true; // Morocco
        supportedCountries[840] = true; // United States
        supportedCountries[724] = true; // Spain
        supportedCountries[620] = true; // Portugal
    }

    // ── Modifiers ──────────────────────────────────────────────
    modifier onlyVerifier() {
        if (!authorizedVerifiers[msg.sender] && msg.sender != owner()) {
            revert UnauthorizedVerifier();
        }
        _;
    }

    modifier validTier(Tier tier) {
        if (tier == Tier.None) revert InvalidTier();
        _;
    }

    // ── QIE Pass Integration ────────────────────────────────────

    function setQiePassSigner(address _qiePassSigner) external onlyOwner {
        address oldSigner = qiePassSigner;
        qiePassSigner = _qiePassSigner;
        emit QiePassSignerUpdated(oldSigner, _qiePassSigner);
    }

    function linkQIEAttestation(
        address user,
        bytes32 credentialHash,
        uint256 expiresAt,
        bytes32 claimsMerkleRoot,
        bytes calldata qieSignature
    ) external onlyVerifier {
        if (qiePassSigner == address(0)) revert UnauthorizedVerifier();
        if (passportId[user] == 0) revert IdentityNotFound();

        bytes32 message = keccak256(abi.encodePacked(user, credentialHash, expiresAt, claimsMerkleRoot));
        bytes32 ethSignedMessage = message.toEthSignedMessageHash();
        address signer = ethSignedMessage.recover(qieSignature);

        if (signer != qiePassSigner) revert InvalidQIESignature();

        qieAttestations[user] = QIEAttestation({
            credentialHash: credentialHash,
            attestedAt: block.timestamp,
            expiresAt: expiresAt,
            claimsMerkleRoot: claimsMerkleRoot,
            isValid: true
        });

        emit QIEAttestationLinked(user, credentialHash, expiresAt);
        _processVerifiedClaims(user, claimsMerkleRoot);
    }

    function revokeQIEAttestation(address user) external onlyVerifier {
        QIEAttestation storage attestation = qieAttestations[user];
        if (!attestation.isValid) revert IdentityNotFound();
        attestation.isValid = false;
        emit QIEAttestationRevoked(user, attestation.credentialHash);
    }

    function hasValidQIEAttestation(address user) external view returns (bool) {
        QIEAttestation storage att = qieAttestations[user];
        return att.isValid && block.timestamp < att.expiresAt;
    }

    // ── Admin ──────────────────────────────────────────────────

    function authorizeVerifier(address verifier, bool authorized) external onlyOwner {
        authorizedVerifiers[verifier] = authorized;
        emit VerifierAuthorized(verifier, authorized);
    }

    function setCountrySupport(uint256 countryCode, bool supported, string calldata countryName) external onlyOwner {
        supportedCountries[countryCode] = supported;
        emit CountrySupportUpdated(countryCode, supported, countryName);
    }

    function setTierRequirements(Tier tier, uint256 minDeposit, uint256 maxUnsecured, bool lendingAccess)
        external
        onlyOwner
        validTier(tier)
    {
        minDepositAmount[tier] = minDeposit;
        maxUnsecuredLimit[tier] = maxUnsecured;
        tierCanAccessLending[tier] = lendingAccess;
    }

    // ── Identity Issuance ──────────────────────────────────────

    /**
     * @notice Issue a new identity passport.
     * @dev On first issuance for a given biometricHash a fresh canonical ID is
     *      minted. All subsequent issuances (post-reinstatement) reuse that ID.
     */
    function issueIdentity(
        address user,
        Tier tier,
        bytes32 biometricHash,
        bytes32 documentHash,
        bytes32 livenessProof,
        uint256 countryCode,
        uint256 validityDays
    ) external onlyVerifier validTier(tier) {
        if (passportId[user] != 0) revert AlreadyHasIdentity();

        _validateNewIdentity(biometricHash, documentHash, countryCode);

        uint256 tokenId = _resolveCanonicalId(biometricHash);
        passportId[user] = tokenId;
        usedBiometrics[biometricHash] = true;
        usedDocuments[documentHash] = true;

        identities[tokenId] = Identity({
            tier: tier,
            issuedAt: block.timestamp,
            expiresAt: block.timestamp + (validityDays * 1 days),
            biometricHash: biometricHash,
            documentHash: documentHash,
            livenessProof: livenessProof,
            countryCode: countryCode,
            frozen: false,
            lastRevoked: 0
        });

        _mint(user, tokenId);
        emit IdentityIssued(user, tokenId, tier, countryCode, biometricHash);
    }

    function upgradeTier(address user, Tier newTier, bytes32 newLivenessProof, uint256 additionalValidityDays)
        external
        onlyVerifier
        validTier(newTier)
    {
        uint256 tokenId = passportId[user];
        if (tokenId == 0) revert IdentityNotFound();

        Identity storage identity = identities[tokenId];
        if (identity.frozen) revert IdentityFrozen();
        if (uint256(newTier) <= uint256(identity.tier)) revert InvalidTier();

        Tier oldTier = identity.tier;
        identity.tier = newTier;
        identity.livenessProof = newLivenessProof;
        identity.expiresAt += additionalValidityDays * 1 days;

        emit TierUpgraded(user, newTier, uint256(oldTier));
    }

    /**
     * @notice Revoke an identity.
     * @dev Mirrors `biometricLastRevoked` from the Identity struct to the
     *      persistent mapping BEFORE clearing the struct, ensuring the
     *      REVOCATION_COOLDOWN is honoured on any future re-registration
     *      attempt with the same biometrics.
     *      documentHash is freed so the document can be re-registered after
     *      the cooldown (same as biometrics behaviour).
     */
    function revokeIdentity(address user, string calldata reason) external onlyVerifier {
        uint256 tokenId = passportId[user];
        if (tokenId == 0) revert IdentityNotFound();

        Identity storage identity = identities[tokenId];

        // Persist cooldown timestamp BEFORE wiping struct.
        biometricLastRevoked[identity.biometricHash] = block.timestamp;

        // Free hashes so they can be reused after the cooldown.
        usedBiometrics[identity.biometricHash] = false;
        usedDocuments[identity.documentHash] = false;

        identity.frozen = true;
        identity.lastRevoked = block.timestamp;

        _burn(tokenId);
        passportId[user] = 0;

        emit IdentityRevoked(user, reason, block.timestamp + REVOCATION_COOLDOWN);
    }

    /**
     * @notice Reinstate a previously revoked identity.
     * @dev Uses _resolveCanonicalId so the reinstated passport reuses the
     *      original token ID, preserving the full credit/bad-debt history
     *      tied to that ID in downstream contracts.
     *      Only callable by owner (same as v1).
     */
    function reinstateIdentity(
        address user,
        Tier tier,
        bytes32 biometricHash,
        bytes32 documentHash,
        bytes32 livenessProof,
        uint256 countryCode,
        uint256 validityDays
    ) external onlyOwner validTier(tier) {
        if (passportId[user] != 0) revert AlreadyHasIdentity();

        _validateNewIdentity(biometricHash, documentHash, countryCode);

        // Reuse the canonical ID — this is the critical difference from v1.
        uint256 tokenId = _resolveCanonicalId(biometricHash);
        passportId[user] = tokenId;
        usedBiometrics[biometricHash] = true;
        usedDocuments[documentHash] = true;

        identities[tokenId] = Identity({
            tier: tier,
            issuedAt: block.timestamp,
            expiresAt: block.timestamp + (validityDays * 1 days),
            biometricHash: biometricHash,
            documentHash: documentHash,
            livenessProof: livenessProof,
            countryCode: countryCode,
            frozen: false,
            lastRevoked: 0
        });

        _mint(user, tokenId);
        emit IdentityReinstated(user);
    }

    // ── View Functions ─────────────────────────────────────────

    function isVerified(address user) external view returns (bool) {
        return _isVerifiedWithMinTier(user, Tier.Basic);
    }

    function isVerifiedWithTier(address user, Tier minTier) external view returns (bool) {
        return _isVerifiedWithMinTier(user, minTier);
    }

    function getTier(address user) external view returns (Tier) {
        uint256 tokenId = passportId[user];
        if (tokenId == 0) return Tier.None;

        Identity storage identity = identities[tokenId];
        if (identity.frozen || block.timestamp > identity.expiresAt) {
            return Tier.None;
        }
        return identity.tier;
    }

    function getIdentity(address user)
        external
        view
        returns (
            Tier tier,
            uint256 issuedAt,
            uint256 expiresAt,
            uint256 countryCode,
            bool isActive,
            bool canAccessLending_
        )
    {
        uint256 tokenId = passportId[user];
        if (tokenId == 0) return (Tier.None, 0, 0, 0, false, false);

        Identity storage identity = identities[tokenId];
        bool active = !identity.frozen && block.timestamp <= identity.expiresAt;

        return (
            identity.tier,
            identity.issuedAt,
            identity.expiresAt,
            identity.countryCode,
            active,
            active && tierCanAccessLending[identity.tier]
        );
    }

    function isExpired(address user) external view returns (bool) {
        uint256 tokenId = passportId[user];
        if (tokenId == 0) return true;
        return block.timestamp > identities[tokenId].expiresAt;
    }

    function getMaxUnsecuredLimit(address user) external view returns (uint256) {
        Tier tier = this.getTier(user);
        return maxUnsecuredLimit[tier];
    }

    function checkLendingAccess(address user) external view returns (bool) {
        Tier tier = this.getTier(user);
        return tierCanAccessLending[tier];
    }

    /**
     * @notice Returns the number of seconds remaining in the revocation cooldown
     *         for a given biometric hash. Returns 0 if no cooldown is active.
     * @dev Useful for frontends to display "you can re-register in X days".
     */
    function cooldownRemaining(bytes32 biometricHash) external view returns (uint256) {
        uint256 lastRevoked = biometricLastRevoked[biometricHash];
        if (lastRevoked == 0) return 0;
        uint256 cooldownEnd = lastRevoked + REVOCATION_COOLDOWN;
        if (block.timestamp >= cooldownEnd) return 0;
        return cooldownEnd - block.timestamp;
    }

    // ── Compliance ─────────────────────────────────────────────

    function freezeIdentity(address user) external onlyOwner {
        uint256 tokenId = passportId[user];
        if (tokenId == 0) revert IdentityNotFound();
        identities[tokenId].frozen = true;
    }

    function unfreezeIdentity(address user) external onlyOwner {
        uint256 tokenId = passportId[user];
        if (tokenId == 0) revert IdentityNotFound();
        identities[tokenId].frozen = false;
    }

    // ── Soulbound Enforcement ──────────────────────────────────

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            revert("QIEIdentity: non-transferable");
        }
        return super._update(to, tokenId, auth);
    }

    function approve(address, uint256) public pure override {
        revert("QIEIdentity: non-transferable");
    }

    function setApprovalForAll(address, bool) public pure override {
        revert("QIEIdentity: non-transferable");
    }
}
