// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "./QIEIdentity.sol";

contract QIEBadDebt is ERC721, Ownable2Step {
    error Soulbound();
    error UnauthorizedMinter();
    error TokenNotFound();
    error AlreadyHasActiveBadDebt();
    error IdentityRequired();

    struct BadDebtRecord {
        uint256 passportId;
        uint256 principalLost;
        uint256 interestLost;
        uint256 lateFeesLost;
        uint256 defaultedAt;
        uint256 repaidAt;
        bool repaid;
        uint8 tierAtDefault;
    }

    QIEIdentity public immutable identity;
    mapping(address => bool) public authorizedMinters;
    mapping(uint256 => uint256) public passportToActiveBadDebt;
    mapping(uint256 => BadDebtRecord) public records;
    mapping(uint256 => uint256[]) public passportDefaultHistory;
    uint256 private _tokenIdCounter;

    event BadDebtMinted(
        uint256 indexed tokenId,
        uint256 indexed passportId,
        address indexed borrower,
        uint256 principalLost,
        uint256 totalLost,
        uint8 tierAtDefault
    );
    event BadDebtRepaid(
        uint256 indexed tokenId,
        uint256 indexed passportId,
        address indexed borrower,
        uint256 repaymentAmount,
        uint256 repaidAt
    );
    event MinterAuthorized(address indexed minter, bool authorized);

    constructor(address _identity) ERC721("QIE Bad Debt", "QIE-DEFAULT") Ownable(msg.sender) {
        if (_identity == address(0)) revert IdentityRequired();
        identity = QIEIdentity(_identity);
    }

    modifier onlyMinter() {
        if (!authorizedMinters[msg.sender]) revert UnauthorizedMinter();
        _;
    }

    function authorizeMinter(address minter, bool authorized) external onlyOwner {
        authorizedMinters[minter] = authorized;
        emit MinterAuthorized(minter, authorized);
    }

    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function mintBadDebt(
        address borrower,
        uint256 principalLost,
        uint256 interestLost,
        uint256 lateFeesLost,
        uint8 tierAtDefault
    ) external onlyMinter returns (uint256 tokenId) {
        uint256 passportId = identity.passportId(borrower);
        if (passportId == 0) revert IdentityRequired();

        uint256 existing = passportToActiveBadDebt[passportId];
        if (existing != 0 && _tokenExists(existing)) revert AlreadyHasActiveBadDebt();

        tokenId = ++_tokenIdCounter;
        uint256 totalLost = principalLost + interestLost + lateFeesLost;

        records[tokenId] = BadDebtRecord(
            passportId, principalLost, interestLost, lateFeesLost, block.timestamp, 0, false, tierAtDefault
        );
        passportToActiveBadDebt[passportId] = tokenId;
        passportDefaultHistory[passportId].push(tokenId);

        _mint(borrower, tokenId);
        emit BadDebtMinted(tokenId, passportId, borrower, principalLost, totalLost, tierAtDefault);
    }

    function burnOnRepayment(uint256 tokenId, uint256 repaymentAmount) external onlyMinter {
        if (!_tokenExists(tokenId)) revert TokenNotFound();

        BadDebtRecord storage record = records[tokenId];
        address borrower = ownerOf(tokenId);
        uint256 passportId = record.passportId;

        record.repaid = true;
        record.repaidAt = block.timestamp;
        passportToActiveBadDebt[passportId] = 0;

        _burn(tokenId);
        emit BadDebtRepaid(tokenId, passportId, borrower, repaymentAmount, block.timestamp);
    }

    function hasActiveBadDebt(address user) external view returns (bool) {
        uint256 passportId = identity.passportId(user);
        if (passportId == 0) return false;
        uint256 tokenId = passportToActiveBadDebt[passportId];
        return tokenId != 0 && _tokenExists(tokenId);
    }

    function hasActiveBadDebtByPassport(uint256 passportId) external view returns (bool) {
        uint256 tokenId = passportToActiveBadDebt[passportId];
        return tokenId != 0 && _tokenExists(tokenId);
    }

    function totalDefaultsForPassport(uint256 passportId) external view returns (uint256) {
        return passportDefaultHistory[passportId].length;
    }

    function getDefaultHistory(address user) external view returns (uint256[] memory) {
        uint256 passportId = identity.passportId(user);
        if (passportId == 0) return new uint256[](0);
        return passportDefaultHistory[passportId];
    }

    function getBadDebtInfo(uint256 tokenId)
        external
        view
        returns (BadDebtRecord memory record, bool exists, address currentOwner)
    {
        record = records[tokenId];
        exists = _tokenExists(tokenId);
        currentOwner = exists ? ownerOf(tokenId) : address(0);
    }

    function getActiveBadDebtToken(address user) external view returns (uint256) {
        uint256 passportId = identity.passportId(user);
        if (passportId == 0) return 0;
        uint256 tokenId = passportToActiveBadDebt[passportId];
        return _tokenExists(tokenId) ? tokenId : 0;
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) revert Soulbound();
        return super._update(to, tokenId, auth);
    }

    function approve(address to, uint256 tokenId) public pure override {
        revert Soulbound();
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert Soulbound();
    }
}
