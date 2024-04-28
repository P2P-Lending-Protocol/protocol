// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

///////////////
/// errors ///
/////////////
error Protocol__MustBeMoreThanZero();
error Protocol__tokensAndPriceFeedsArrayMustBeSameLength();
error Protocol__TokenNotAllowed();
error Protocol__TransferFailed();
error Protocol__BreaksHealthFactor();
error Protocol__InsufficientCollateral();
error Protocol__RequestNotOpen();
error Protocol__InsufficientBalance();
error Protocol__IdNotExist();
error Protocol__InvalidId();
error Protocol__Unauthorized();
 
error Protocol__OfferNotOpen();
error  Protocol__InvalidToken();
error  Protocol__InsufficientAllowance();