from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_gt
)

from openzeppelin.access.ownable import Ownable_initializer

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
        _amount0=amount0,
        _amount1=amount1,
        _owner=caller_address
    )
    return ()
end

@external 
func remove_liquidity{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
    ):
    let (check_amount0) = uint256_gt(amount0, 0)
    let (check_amount1) = uint256_gt(amount1, 0)
    with_attr error_message("LP Error: Amount is too small"):
        assert check_amount0 = 1
        assert check_amount1 = 1
    end



        



