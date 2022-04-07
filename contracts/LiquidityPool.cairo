from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_gt
)

from openzeppelin.access.ownable import Ownable_initializer

from contracts.interfaces.ILiquidityCertificate import ILiquidityCertificate

#
# Storage variables
#

@storage_var
func _token_pair(token0: felt) -> (token1: felt):
end

@storage_var
func _liquidity_certificate() -> (certificate_address: felt):
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
        amount: Uint256
    ):
    let (check_amount) = uint256_gt(amount, 0)
    with_attr error_message("LP Error: Amount is too small"):
        assert check_amount = 1
    end
    let (liquidity_certificate) = _liquidity_certificate.read()
    ILiquidityCertificate.mint(
        contract_address=liquidity_certificate,

@external
func remove_liquidity{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        to: felt
    )
        



