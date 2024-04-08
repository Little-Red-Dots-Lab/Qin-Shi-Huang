// SPDX-License-Identifier: MIT
// Creator: Ric Li C (Twitter @Ric_Li_C)
// Ric Li C's solution of ERC20, version 0.1
// Inspired by Simplify (Twitter @Simplify_ERC314)
// Revised based on OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.18;

import {IERC20CMetadata} from "./IERC20C_Metadata_v0.1.sol";
import {IERC20CErrors} from "./IERC20C_Errors_v0.1.sol";
import {Ownable} from "../lib/Ownable.sol";
import {ReentrancyGuard} from "../lib/ReentrancyGuard.sol";

/**
 * Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20C is
    IERC20CMetadata,
    IERC20CErrors,
    Ownable,
    ReentrancyGuard
{
    // =============================================================
    //                           STORAGE
    // =============================================================
    // Token name.
    string private _name;

    // Token symbol.
    string private _symbol;

    // Token amount in existence, excluding burned amount, including decimals.
    uint256 private _totalSupply;

    // Mapping address to account balance.
    mapping(address account => uint256) private _balances;

    // Token price for fair launch.
    uint256 internal _fairLaunchPrice;

    // Token amount for fair launch.
    uint256 private _fairLaunchAmount;

    // Maximum token amount for one account during fair launch.
    uint256 private _fairLaunchLimit;

    // Returns if liquidity is ready.
    bool private _isLiquidityReady;

    // Eth amount for liquidity.
    uint256 private _ethLiquidity;

    // Token amount for liquidity.
    uint256 private _tokenLiquidity;

    // Maximum token amount for one account after fair launch.
    uint256 internal _accountLimit;

    // Token amount for reward if condition is met.
    uint256 internal _lockedReward;

    mapping(address account => mapping(address spender => uint256))
        private _allowances;

    // =============================================================
    //                         CONSTRUCTOR
    // =============================================================
    /**
     * Initialize parameters.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 lockedReward_,
        uint256 fairLaunchPrice_,
        uint256 fairLaunchLimit_,
        uint256 accountLimit_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _lockedReward = lockedReward_;
        _fairLaunchPrice = fairLaunchPrice_;
        _fairLaunchLimit = fairLaunchLimit_;
        unchecked {
            _fairLaunchAmount = (_totalSupply - _lockedReward) / 2;
            _ethLiquidity =
                (_fairLaunchAmount * _fairLaunchPrice) /
                (10 ** decimals());
        }
        _tokenLiquidity = _fairLaunchAmount;
        _accountLimit = accountLimit_;

        _balances[address(this)] = _totalSupply;
    }

    // =============================================================
    //                            METADATA
    // =============================================================
    /**
     * Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function getFairLaunchInfo()
        public
        view
        virtual
        returns (uint256, uint256, uint256)
    {
        return (_fairLaunchPrice, _fairLaunchAmount, _fairLaunchLimit);
    }

    function getLiquidityInfo()
        public
        view
        virtual
        returns (bool, uint256, uint256, uint256)
    {
        return (
            _isLiquidityReady,
            _ethLiquidity,
            _tokenLiquidity,
            _accountLimit
        );
    }

    /**
     * The default value of {unlockMultiplier} is 10. If needed, please override
     * this function so it returns a different value.
     */
    function unlockMultiplier() public view virtual returns (uint8) {
        return 10;
    }

    function lockedReward() public view virtual returns (uint256) {
        return _lockedReward;
    }

    // =============================================================
    //                      SETTING FUNCTIONS
    // =============================================================
    /**
     * Only owner of the contract is allowed to call this function.
     */
    function setFairLaunchLimit(uint256 newLimit) public virtual onlyOwner {
        _fairLaunchLimit = newLimit;
    }

    /**
     * Only owner of the contract is allowed to call this function.
     */
    function setAccountLimit(uint256 newLimit) public virtual onlyOwner {
        _accountLimit = newLimit;
    }

    // =============================================================
    //                      TOKEN FUNCTIONS
    // =============================================================
    /**
     * See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * See {IERC20-transfer}.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        if (to == address(this)) {
            // Sell Scenario.
            _sell(_msgSender(), amount);
        } else {
            // Transfer Scenario.
            _transfer(_msgSender(), to, amount);
        }
        return true;
    }

    /**
     * See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        if (to == address(this)) {
            // Sell Scenario.
            _sell(from, amount);
        } else {
            // Transfer Scenario.
            _transfer(from, to, amount);
        }
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (_balances[from] < amount) {
            revert ERC20C_InsufficientBalance(from, _balances[from], amount);
        }

        unchecked {
            _balances[from] = _balances[from] - amount;
        }

        if (to == address(0)) {
            unchecked {
                _totalSupply -= amount;
            }
        } else {
            unchecked {
                _balances[to] += amount;
            }
        }

        emit Transfer(from, to, amount);
    }

    /**
     * Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20C_InsufficientAllowance(
                    spender,
                    currentAllowance,
                    value
                );
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }

    /**
     * See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 value
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(
        address owner,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal virtual {
        if (owner == address(0)) {
            revert ERC20C_InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20C_InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    // =============================================================
    //                          MODIFIER
    // =============================================================
    modifier LiquidityReady() {
        if (!_isLiquidityReady) {
            revert ERC20C_LiquidityNotReady(_msgSender());
        }
        _;
    }

    // =============================================================
    //                      TRADING FUNCTIONS
    // =============================================================
    /**
     * Conduct public fair launch.
     *
     * To prevent whale holders, in the fair launch, each account is limited to
     * buy `_fairLaunchLimit` amount of tokens.
     */
    function fairLaunch() public payable virtual {
        uint256 amountInteger;
        uint256 amount;
        unchecked {
            amountInteger = _msgValue() / _fairLaunchPrice;
            amount = amountInteger * 10 ** decimals();
        }
        if (_balances[_msgSender()] + amount > _fairLaunchLimit) {
            revert ERC20C_ExceedFairLaunchLimit(
                _balances[_msgSender()],
                amount,
                _fairLaunchLimit
            );
        }
        if (amountInteger <= 0) {
            revert ERC20C_TokenAmountTooLow(_msgSender(), _msgValue());
        }

        if (_fairLaunchAmount > 0) {
            if (amount >= _fairLaunchAmount) {
                uint256 ethAmount;
                if (amount > _fairLaunchAmount) {
                    unchecked {
                        ethAmount =
                            (_fairLaunchAmount * _fairLaunchPrice) /
                            (10 ** decimals());
                    }
                } else {
                    ethAmount = _msgValue();
                }

                unchecked {
                    _balances[address(this)] =
                        _balances[address(this)] -
                        _fairLaunchAmount;
                    _balances[_msgSender()] += _fairLaunchAmount;
                }
                emit FairLaunch(_msgSender(), ethAmount, _fairLaunchAmount);

                _isLiquidityReady = true;

                if (amount > _fairLaunchAmount) {
                    uint256 buyEthAmount;
                    unchecked {
                        buyEthAmount = _msgValue() - ethAmount;
                    }
                    _buy(buyEthAmount);
                }

                _fairLaunchAmount = 0;
            } else {
                unchecked {
                    _balances[address(this)] =
                        _balances[address(this)] -
                        amount;
                    _balances[_msgSender()] += amount;
                    _fairLaunchAmount -= amount;
                }

                emit FairLaunch(_msgSender(), _msgValue(), amount);
            }
        }
    }

    /**
     * Buys tokens with ETH.
     */
    function buy() public payable virtual {
        _buy(_msgValue());
    }

    function _buy(uint256 ethAmount) internal virtual LiquidityReady {
        uint256 tokenAmount = getEstimation(true, ethAmount);

        if (
            (_accountLimit > 0) &&
            (tokenAmount + _balances[_msgSender()] > _accountLimit)
        ) {
            revert ERC20C_ExceedAccountLimit(
                _msgSender(),
                _balances[_msgSender()],
                tokenAmount,
                _accountLimit
            );
        }
        if (tokenAmount <= 0) {
            revert ERC20C_TokenAmountTooLow(_msgSender(), ethAmount);
        }
        if (balanceOf(address(this)) < tokenAmount) {
            revert ERC20C_InsufficientTokenAmount(
                _msgSender(),
                tokenAmount,
                balanceOf(address(this))
            );
        }

        unchecked {
            _balances[address(this)] = _balances[address(this)] - tokenAmount;
            _balances[_msgSender()] += tokenAmount;
            _ethLiquidity += ethAmount;
            _tokenLiquidity -= tokenAmount;
        }

        _checkPriceAndUnlock();

        emit Swap(_msgSender(), ethAmount, tokenAmount, 0, 0);
    }

    /**
     * Sells tokens for ETH.
     */
    function sell(uint256 tokenAmount) public virtual {
        _sell(_msgSender(), tokenAmount);
    }

    function _sell(
        address account,
        uint256 tokenAmount
    ) internal virtual LiquidityReady nonReentrant {
        uint256 ethAmount = getEstimation(false, tokenAmount);

        if (ethAmount <= 0) {
            revert ERC20C_EthAmountTooLow(account, tokenAmount);
        }
        if (address(this).balance < ethAmount) {
            revert ERC20C_InsufficientEthAmount(
                account,
                ethAmount,
                address(this).balance
            );
        }

        unchecked {
            _balances[account] = _balances[account] - tokenAmount;
            _balances[address(this)] += tokenAmount;
            _ethLiquidity -= ethAmount;
            _tokenLiquidity += tokenAmount;
        }
        (bool success, ) = account.call{value: ethAmount}("");
        if (!success) {
            revert ERC20C_TransferEthFailed(account, ethAmount);
        }

        emit Swap(account, 0, 0, tokenAmount, ethAmount);
    }

    /**
     * Estimates the amount of tokens or ETH to receive when buying or selling.
     * @param amount: the amount of ETH or tokens to swap.
     * @param isBuy: true for buying, false for selling.
     */
    function getEstimation(
        bool isBuy,
        uint256 amount
    ) public view virtual returns (uint256) {
        uint256 amountOut;
        if (isBuy) {
            unchecked {
                amountOut =
                    (amount * _tokenLiquidity) /
                    (_ethLiquidity + amount);
            }
        } else {
            unchecked {
                amountOut =
                    (amount * _ethLiquidity) /
                    (_tokenLiquidity + amount);
            }
        }

        return amountOut;
    }

    function getPrice() public view virtual returns (uint256) {
        uint256 price;
        unchecked {
            price = (_ethLiquidity * 10 ** 18) / _tokenLiquidity;
        }

        return price;
    }

    // =============================================================
    //                  REWARD UNLOCK FUNCTIONS
    // =============================================================
    function _checkPriceAndUnlock() internal virtual {
        uint256 price = getPrice();
        uint256 multiplier = price / _fairLaunchPrice;
        if (multiplier >= unlockMultiplier()) {
            _unlock(multiplier);
        }
    }

    /**
     * Unlocks reward, needs to be overriden in contract realization.
     */
    function _unlock(uint256 multiplier) internal virtual {}

    // =============================================================
    //                       FALLBACK FUNCTION
    // =============================================================
    /**
     * Fallback function to get tokens with ETH.
     */
    receive() external payable virtual {
        if (_isLiquidityReady) {
            buy();
        } else {
            fairLaunch();
        }
    }
}
