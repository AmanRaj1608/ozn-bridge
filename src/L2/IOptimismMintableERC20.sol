// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IOptimismMintableERC20
 * @dev Interface for ERC20 tokens that can be minted and burned by the L2 Standard Bridge.
 */
interface IOptimismMintableERC20 is IERC20 {
    /**
     * @dev Mints `_amount` tokens to `_to` address.
     * @param _to Address to mint tokens to.
     * @param _amount Amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @dev Burns `_amount` tokens from `_from` address.
     * @param _from Address to burn tokens from.
     * @param _amount Amount of tokens to burn.
     */
    function burn(address _from, uint256 _amount) external;

    /**
     * @dev Returns the address of the L1 token contract that this token represents.
     */
    function l1Token() external view returns (address);

    /**
     * @dev Returns the address of the L2 bridge contract that is allowed to mint/burn this token.
     */
    function l2Bridge() external view returns (address);
}
