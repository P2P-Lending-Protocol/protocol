// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

        

    event RequestCreated(address indexed _borrower,uint96 indexed requestId,uint  _amount, uint8 _interest);
    event OfferCreated(address indexed _lender,address indexed_tokenAddress, uint256 _amount, uint96 indexed _requestId);
    event RespondToLendingOffer(address indexed sender,uint indexed _offerId, uint8 _status, uint8 _offerStatus);
    event ServiceRequestSuccessful(address indexed sender,address indexed _borrower,uint8 _requestId,uint256 amount);
    event  CollateralWithdrawn(address indexed sender, address indexed  _tokenCollateralAddress, uint256 _amount);


