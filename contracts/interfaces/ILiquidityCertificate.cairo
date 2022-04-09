%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ILiquidityCertificate:

    func get_token_id(
            pair: felt,
            owner: felt
        ) -> (
            token_id: Uint256
        ):
    end

    func mint(
            owner: felt,
            liquidity: Uint256
        ):
    end

    func burn(
            token_id: Uint256
        ):
    end
end
    
