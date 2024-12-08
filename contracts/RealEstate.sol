// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RealEstateNFT is ERC721 {
    uint256 public nextTokenId;
    string private baseURI;

    constructor(
        string memory _baseURI
    ) ERC721("Real Estate NFT", "REALESTATE") {
        baseURI = _baseURI;
    }

    function mint(address to) public {
        _safeMint(to, nextTokenId);
        nextTokenId++;
    }
}

contract RealEstateEscrow {
    address public seller;
    address public buyer;
    address public lender;
    uint256 public price;
    bool public isNegotiated;
    RealEstateNFT public realEstateNFT;

    enum State {
        Listed,
        OfferMade,
        OfferAccepted,
        LoanApproved,
        Sold
    }
    State public state;

    constructor(uint256 _price, address nftContract) {
        seller = msg.sender;
        price = _price;
        state = State.Listed;
        realEstateNFT = RealEstateNFT(nftContract);
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Not the buyer");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Not the seller");
        _;
    }

    modifier inState(State _state) {
        require(state == _state, "Invalid state");
        _;
    }

    function makeOffer() public inState(State.Listed) {
        buyer = msg.sender;
        state = State.OfferMade;
    }

    function acceptOffer() public onlySeller inState(State.OfferMade) {
        state = State.OfferAccepted;
    }

    function approveLoan() public inState(State.OfferAccepted) {
        lender = msg.sender;
        state = State.LoanApproved;
    }

    function finalizeSale()
        public
        payable
        onlyBuyer
        inState(State.LoanApproved)
    {
        require(msg.value == price, "Incorrect payment");
        payable(seller).transfer(msg.value);
        realEstateNFT.mint(buyer);
        state = State.Sold;
    }

    function negotiatePrice(
        uint256 newPrice
    ) public onlyBuyer inState(State.OfferMade) {
        // Implementing zero-sum game for negotiation
        uint256 sellerUtility = price - newPrice;
        uint256 buyerUtility = newPrice - price;

        require(
            sellerUtility + buyerUtility == 0,
            "Invalid negotiation: zero-sum condition not met"
        );

        price = newPrice;
        isNegotiated = true;
    }
}
