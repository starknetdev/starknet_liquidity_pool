%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (
    assert_le, 
    assert_lt,
    assert_not_zero
)
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_contract_address
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_lt,
    uint256_le,
    uint256_eq,
    uint256_mul,
    uint256_unsigned_div_rem
)

from openzeppelin.access.ownable import Ownable_initializer
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from contracts.interfaces.ILiquidityCertificate import ILiquidityCertificate
from contracts.utils.constants import FALSE, TRUE

#
# Storage variables
#

@storage_var
func _token0() -> (res: felt):
end

@storage_var
func _token1() -> (res: felt):
end

@storage_var
func _pair() -> (res: felt):
end

@storage_var
func _reserve0() -> (res: Uint256):
end

@storage_var
func _reserve1() -> (res: Uint256):
end

@storage_var
func _liquidity_certificate() -> (res: felt):
end

#
# Getters
#

@view
func get_reserves{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (
        reserve0: Uint256, 
        reserve1: Uint256
    ):
    let (reserve0) = _reserve0.read()
    let (reserve1) = _reserve1.read()
    return (reserve0, reserve1)
end

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        token0: felt,
        token1: felt,
        liquidity_certificate: felt,
        owner: felt
    ):
    _token0.write(token0)
    _token1.write(token1)
    _pair.write(token0 + token1)
    _liquidity_certificate.write(liquidity_certificate)
    Ownable_initializer(owner)
    return ()
end

#
# External
#

@external
func add_liquidity{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        amount0: Uint256,
        amount1: Uint256
    ):
    alloc_locals
    let (check_amount0) = uint256_lt(Uint256(0,0), amount0)
    let (check_amount1) = uint256_lt(Uint256(0,0), amount1)
    with_attr error_message("LP Error: Amount is too small"):
        assert_not_zero(check_amount0 + check_amount1)
    end

    let (reserve0: Uint256, reserve1: Uint256) = get_reserves()

    # First liquidity transaction
    let check_reserves: Uint256 = uint256_add(reserve0,reserve1)
    let (local check_reserves_zero) = uint256_eq(check_reserves,Uint256(0,0))
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr
    if check_reserves_zero == TRUE:
        tempvar calculated_amount0: Uint256 = amount0
        tempvar calculated_amount1: Uint256 = amount1
    else:

        # Get optimal amount of token0
        let (amount0_optimal) = get_optimal_pair_amount(amount1, reserve1, reserve0)

        # Check the amount0 inputed is larger or equal to the optimal amount
        let (local check_optimal0) = uint256_le(amount0_optimal, amount0)
        if check_optimal0 == TRUE:
            tempvar calculated_amount0: Uint256 = amount0_optimal
            tempvar calculated_amount1: Uint256 = amount1
        else:
            # Get optimal amount of token1
            let (amount1_optimal) = get_optimal_pair_amount(amount0, reserve0, reserve1)

            # Check the amount1 inputed is larger or equal to the optimal amount
            let (local check_optimal1) = uint256_le(amount1_optimal, amount1)

            # Assert the optimal amount to be at least larger than the optimal (should never be true)
            assert check_optimal1 = TRUE
            tempvar calculated_amount0: Uint256 = amount0
            tempvar calculated_amount1: Uint256 = amount1_optimal
        end
    end

    ## TODO: implement tempvars to fix revoked references
    ##       below does not fix
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    let (token0) = _token0.read()
    let (token1) = _token1.read()
    IERC20.transferFrom(
        contract_address=token0, 
        sender=caller_address, 
        recipient=contract_address,
        amount=calculated_amount0
    )
    IERC20.transferFrom(
        contract_address=token1, 
        sender=caller_address, 
        recipient=contract_address,
        amount=calculated_amount1
    )
    let (check_calculated_amounts) = uint256_lt(calculated_amount0, calculated_amount1)
    if check_calculated_amounts == TRUE:
        let liquidity: Uint256 = calculated_amount0
    else:
        let liquidity: Uint256 = calculated_amount1
    end
    let (liquidity_certificate) = _liquidity_certificate.read()
    let (pair) = _pair.read()
    ILiquidityCertificate.mint(
        contract_address=liquidity_certificate,
        pair=pair,
        owner=caller_address,
        liquidity=liquidity
    )
    let (balance0) = IERC20.balanceOf(contract_address=token0, account=contract_address)
    let (balance1) = IERC20.balanceOf(contract_address=token1, account=contract_address)
    _reserve0.write(balance0)
    _reserve1.write(balance1)
    return ()
end

## TODO: Calculate token amounts from liquidity share
@external
func remove_liquidity{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        liquidity: Uint256,
        to: felt
    ):
    alloc_locals
    let (local reserve0, local reserve1) = get_reserves()
    let (token0) = _token0.read()
    let (token1) = _token1.read()
    let (contract_address) = get_contract_address()
    let (balance0) = IERC20.balanceOf(
        contract_address=token0, 
        account=contract_address
    )
    let (balance1) = IERC20.balanceOf(
        contract_address=token1,
        account=contract_address
    )
    # Better to calculate using felt and covert?
    let (amount0_numerator, _) = uint256_mul(liquidity,balance0)
    let (amount1_numerator, _) = uint256_mul(liquidity,balance1)
    let (amount0,_) = uint256_unsigned_div_rem(amount0_numerator, reserve0)
    let (amount1,_) = uint256_unsigned_div_rem(amount1_numerator, reserve1)
    # let (amount1) = (liquidity * balance1) / reserve1
    let (caller_address) = get_caller_address()
    IERC20.transferFrom(
        contract_address=token0, 
        sender=caller_address, 
        recipient=contract_address, 
        amount=amount0
    )
    IERC20.transferFrom(
        contract_address=token1, 
        sender=caller_address, 
        recipient=contract_address, 
        amount=amount1
    )
    let (pair) = _pair.read()
    let (token_id) = ILiquidityCertificate.get_token_id(
        contract_address=contract_address,
        pair=pair, 
        owner=to
    )
    ILiquidityCertificate.burn(contract_address=contract_address, token_id=token_id)
    let (balance0) = IERC20.balanceOf(contract_address=token0, account=contract_address)
    let (balance1) = IERC20.balanceOf(contract_address=token1, account=contract_address)
    _reserve0.write(balance0)
    _reserve1.write(balance1)
    return ()
end


func get_optimal_pair_amount{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        amountA: Uint256,
        reserveA: Uint256,
        reserveB: Uint256
    ) -> (amountB: Uint256):
    alloc_locals
    let (local check_amountA) = uint256_lt(Uint256(0,0), amountA)
    with_attr error_message("LP Error: Amount must be greater than 0"):
        assert check_amountA = TRUE
    end
    # Better to calculate using felt and covert?
    let (amountB_numerator, _) = uint256_mul(amountA, reserveB)
    let (amountB, _) = uint256_unsigned_div_rem(amountB_numerator, reserveA)
    # let (amountB) = (amountA * reserveB) / reserveA
    return (amountB)
end

# func get_amount_out{
#         syscall_ptr: felt*,
#         pedersen_ptr: HashBuiltin*,
#         range_check_ptr
#     }(
#         amount_in: Uint256,
#         reserve_in: Uint256,
#         reserve_out: Uint256
#     ) -> (amount_out: Uint256):
#     let (local check_amount_in) = uint256_lt(0, amount_in)
#     with_attr error_message("LP Error: Amount in must be greater than 0"):
#         assert check_amount_in = 1
#     end
#     let (amount_in_with_fee) = amount_in * 99
#     let (amount_out) = (amount_in_with_fee * reserve_out) / (reserve_in * 100 + amount_in_with_fees)
#     return (amount_out)
# end


# @external
# func swap{
#         syscall_ptr: felt*,
#         pedersen_ptr: HashBuiltin*,
#         range_check_ptr
#     }(
#         amount0_out: Uint256,
#         amount1_out: Uint256,
#         to: felt
#     ):
#     alloc_locals

#     # Check not zero
#     let (local check_amount0) = uint256_lt(0, amount0_out)
#     let (local check_amount1) = uint256_lt(0, amount1_out)
#     with_attr error_message("Swap Error: Amount must be greater than 0"):
#         assert_not_zero(check_amount0 + check_amount1)
#     end

#     # Check amount is less than reserve
#     let (reserve0, reserve1) = get_reserves()
#     let (local check_feasible_amount0) = uint256_lt(amount0, reserve0)
#     let (local check_feasible_amount1) = uint256_lt(amount1, reserve1)
#     with_attr error_message("LP Error: Insuffictient liquidity"):
#         assert (check_feasible_amount0 + check_feasible_amount1) = 2
#     end

#     # Transfer the amount out to swapper
#     let (_token0) = token0.read()
#     let (_token1) = token1.read()
#     if check_amount0 == TRUE:
#         IERC20.transfer(contract_address=token0, recipient=to, amount=amount0)
#     end
#     if check_amount1 == TRUE:
#         IERC20.transfer(contract_address=token1, recipient=to, amount=amount1)
#     end
#     let (contract_address) = get_contract_address()
#     let (balance0) = IERC20.balanceOf(contract_address=token0, account=contract_address)

#     # Check slippage
#     let (amount0_in) = (balance0 > reserve0 - amount0_out) ? balance0 - (reserve0 - amount0_out) : 0
#     let (amount1_in) = (balance1 > reserve1 - amount1_out) ? balance1 - (reserve1 - amount1_out) : 0
#     let (local check_amount0_in) = uint256_lt(0, amount0_in)
#     let (local check_amount1_in) = uint256_lt(0, amount1_in)
#     with_attr error_message("Swap Error: Insufficient input amount"):
#         assert check_amount0_in = TRUE
#         assert check_amount1_in = TRUE
#     end
#     return ()
# end




