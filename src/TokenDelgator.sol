// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TokenDelegator {
    mapping(address => mapping(address => bool)) public approvals;

    // Define the Transfer struct
    struct Transfer {
        IERC20 token;
        address from;
        address to;
        uint256 amount;
    }

    function approve(address _user) public {
        approvals[_user][msg.sender] = true;
    }
    
    function allowance(address _owner, address _spender) public view returns (bool) {
        return approvals[_owner][_spender];
    }

    function transferToken(
        IERC20 token,
        address _from,
        address _to,
        uint256 _amount
    ) public {
        require(approvals[msg.sender][_from], "TokenDelegator: not approved");
        token.transferFrom(_from, address(this), _amount);
        token.transfer(_to, _amount);
    }

    function transferBatch(Transfer[] memory transfers) public {
        for (uint256 i = 0; i < transfers.length; i++) {
            Transfer memory t = transfers[i];
            require(approvals[msg.sender][t.from], "TokenDelegator: not approved for all tokens");
            t.token.transferFrom(t.from, address(this), t.amount);
            t.token.transfer(t.to, t.amount);
        }
    }
}
