from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_contract_address
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_gt
    uint256_gt,
    uint256_lt
)

from openzeppelin.access.ownable import Ownable_initializer

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from contracts.interfaces.ILiquidityCertificate import ILiquidityCertificate

#
# Storage variables
#

@storage_var
func token0() -> (res: felt):
end

@storage_var
func token1() -> (res: felt):
end

@storage_var
func _reserve0() -> (res: Uint256):
end

@storage_var
func _reserve1() -> (res: Uint256):
end

@storage_var
func _token_pair(token0: felt) -> (token1: felt):
end

@storage_var
func _liquidity_certificate() -> (certificate_address: felt):
end

@storage_var
func _reserve_a() -> (res: Uint256):
end

@storage_var
func _reserve_b() -> (res: Uint256):
end

@storage_var
func token0() -> (res: felt):
end

@storage_var
func token1() -> (res: felt):
end


#
# Getters
#

@view
func get_reserves(){
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (reserve_a: Uint256, reserve_b: Uint256):
    let (_reserve_a) = _reserve_a.read()
    let (_reserve_b) = _reserve_b.read()
    return (_reserve_a, _reserve_b)

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
    _token_pair.write(token0, token1)
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
    let (check_amount0) = uint256_gt(amount0, 0)
    let (check_amount1) = uint256_gt(amount1, 0)
    with_attr error_message("LP Error: Amount is too small"):
        assert check_amount0 = 1
        assert check_amount1 = 1
    end
    let (local reserve0) = Uint256_add(_reserve0, amount0)
    let (local reserve1) = Uint256_add(_reserve1, amount1)
    let (liquidity_certificate) = _liquidity_certificate.read()
    let (caller_address) = get_caller_address()
    ILiquidityCertificate.mint(
        contract_address=liquidity_certificate,
        amount0=amount0,
        amount1=amount1
        )

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
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    IERC20.transferFrom(contract_address=token0, sender=caller_address, recipient=contract_address, amount=amount0)
    IERC20.transferFrom(contract_address=token1, sender=caller_address, recipient=contract_address, amount=amount1)
    ILiquidityCertificate.burn(tokenId)
    # First liquidity transaction
    if (reserve0 = 0) & (reserve1 = 0):
        (reserve0, reserve1) = (amount0, amount1)
    else: 


func get_optimal_pair_amount{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        amount0: Uint256,
        reserve0: Uint256,
        reserve1: Uint256
    ) -> (amount1: Uint256):
    let (local check_amount0) = uint256_gt(amount0,0)
    with_attr error_message("LP Error: Amount must be greater than 0"):
        assert check_amount0 = 1
    end
    let (amount1) = (amount1 * reserve2) / reserve1
    return (amount1)
end

func get_amount_out{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        amount_in: Uint256,
        reserve_in: Uint256,
        reserve_out: Uint256
    ) -> (amount_out: Uint256):
    let (local check_amount_in) = uint256_gt(amount_in,0)
    with_attr error_message("LP Error: Amount in must be greater than 0"):
        assert check_amount_in = 1
    end
    let (amount_in_with_fee) = amount_in * 99
    let (amount_out) = (amount_in_with_fee * reserve_out) / (reserve_in * 100 + amount_in_with_fees)
    return (amount_out)
end

@external
func swap{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        amount0_out: Uint256,
        amount1_out: Uint256,
        to: felt
    ):
    alloc_locals

    # Check not zero
    let (local check_amount0) = uint256_gt(amount0_out,0)
    let (local check_amount1) = uint256_gt(amount1_out,0)
    with_attr error_message("Swap Error: Amount must be greater than 0"):
        assert check_amount0 = 1
        assert check_amount0 = 1
    end

    # Check amount is less than reserve
    let (reserve0, reserve1) = get_reserves()
    let (check_feasible_amount0) = uint256_lt(amount0, reserve0)
    let (check_feasible_amount1) = uint256_lt(amount1, reserve1)
    with_attr error_message("LP Error: Insuffictient liquidity"):
        assert check_feasible_amount0 = 1
        assert check_feasible_amount1 = 1
    end

    # Tranbser the amount out to swapper
    let (_token0) = token0.read()
    let (_token1) = token1.read()
    if check_amount0 = 1:
        IERC20.transfer(contract_address=token0, recipient=to, amount=amount0)
    if check_amount1 = 1:
        IERC20.transfer(contract_address=token1, recipient=to, amount=amount1)
    let (contract_address) = get_contract_address()
    let (balance0) = IERC20.balanceOf(contract_address=token0, account=contract_address)

    # Check slippage
    let (amount0_in) = (balance0 > reserve0 - amount0_out) ? balance0 - (reserve0 - amount0_out) : 0
    let (amount1_in) = (balance1 > reserve1 - amount1_out) ? balance1 - (reserve1 - amount1_out) : 0
    let (local check_amount0_in) = uint256_gt(amount0_in,0)
    let (local check_amount1_in) = uint256_gt(amount1_in,0)
    with_attr error_message("Swap Error: Insufficient input amount"):
        assert check_amount0_in = 1
        assert check_amount1_in = 1
    end
    return ()
end

func _update{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        balance0: Uint256,
        balance1: Uint256,
        reserve0: Uint256,
        reserve1: Uint256
    ):




