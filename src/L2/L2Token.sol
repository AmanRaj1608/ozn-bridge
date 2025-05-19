// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./IOptimismMintableERC20.sol";

/**
 * @title L2Token
 * @dev Standard Optimism Mintable ERC20 token that can be bridged from L1.
 * This token is controlled by the L2StandardBridge, which can mint and burn tokens.
 */
contract L2Token is ERC20, IOptimismMintableERC20 {
    address public immutable L1_TOKEN;
    address public immutable L2_BRIDGE;

    modifier onlyL2Bridge() {
        require(
            msg.sender == L2_BRIDGE,
            "L2Token: caller is not the L2 Standard Bridge"
        );
        _;
    }

    constructor(
        address _l2Bridge,
        address _l1Token,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        require(
            _l2Bridge != address(0),
            "L2Token: L2 bridge address cannot be zero"
        );
        require(
            _l1Token != address(0),
            "L2Token: L1 token address cannot be zero"
        );
        L2_BRIDGE = _l2Bridge;
        L1_TOKEN = _l1Token;
    }

    /**
     * @dev See {IOptimismMintableERC20-mint}.
     * Only callable by the L2_BRIDGE.
     */
    function mint(address _to, uint256 _amount) external override onlyL2Bridge {
        _mint(_to, _amount);
    }

    /**
     * @dev See {IOptimismMintableERC20-burn}.
     * Only callable by the L2_BRIDGE.
     * Note: The standard L2StandardBridge calls `burn(msg.sender, _amount)` on this token.
     * For this example, we allow the bridge to specify `_from`.
     * If the bridge requires burning from `msg.sender` (itself), then the L2 bridge should hold the tokens before burning.
     * However, typically the L2 bridge burns from the user who initiated the L2->L1 withdrawal.
     */
    function burn(
        address _from,
        uint256 _amount
    ) external override onlyL2Bridge {
        _burn(_from, _amount);
    }

    function l1Token() external view override returns (address) {
        return L1_TOKEN;
    }

    function l2Bridge() external view override returns (address) {
        return L2_BRIDGE;
    }

    // @note: implementing supportsInterface for ERC165 compatibility
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20Metadata).interfaceId;
    }
}
