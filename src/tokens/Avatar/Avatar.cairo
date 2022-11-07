// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.alloc import alloc

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.security.initializable.library import Initializable
from openzeppelin.security.pausable.library import Pausable
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.upgrades.library import Proxy


from src.tokens.Avatar.library import create_tokenURI, create_data
from src.tokens.Avatar.progress import get_progress
from src.util.str import string, str_concat, str_from_literal

const POINTS_CONTRACT = 0x00c62540e9a10c47a4b7d8abaff468192c66f2d1e979f6bade6e44bf73995982;

@contract_interface
namespace IPointsContract {
    func balanceOf(account: felt) -> (balance: Uint256) {
    }
}

@contract_interface
namespace IAvatarContract {
    func initialize(owner: felt) {
    }

    func balanceOf(owner: felt) -> (balance: Uint256) {
    }

    func ownerOf(tokenId: Uint256) -> (owner: felt) {
    }

    func safeTransferFrom(from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*) {
    }

    func transferFrom(from_: felt, to: felt, tokenId: Uint256) {
    }

    func approve(approved: felt, tokenId: Uint256) {
    }

    func setApprovalForAll(operator: felt, approved: felt) {
    }

    func getApproved(tokenId: Uint256) -> (approved: felt) {
    }

    func isApprovedForAll(owner: felt, operator: felt) -> (isApproved: felt) {
    }

    func owner() -> (owner: felt) {
    }

    func paused() -> (paused: felt) {
    }

    func unpause() {
    }

    func totalSupply() -> (totalSupply: Uint256) {
    }

    func mint(to: felt, tokenId: Uint256) {
    }

    func tokenURI(tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
    }

    func upgrade(implementation: felt) {
    }

    func implementation() -> (implementation: felt) {
    }
}

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt
) {
    Initializable.initialize();
    ERC721.initializer('Cartridge Avatar', 'AVATAR');
    Ownable.initializer(owner);
    Proxy.initializer(owner);
    return ();
}

//
// Getters
//

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    let (success) = ERC165.supports_interface(interfaceId);
    return (success,);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let (name) = ERC721.name();
    return (name,);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    let (symbol) = ERC721.symbol();
    return (symbol,);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    let (balance: Uint256) = ERC721.balance_of(owner);
    return (balance,);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    owner: felt
) {
    let (owner: felt) = ERC721.owner_of(tokenId);
    return (owner,);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (approved: felt) {
    let (approved: felt) = ERC721.get_approved(tokenId);
    return (approved,);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (isApproved: felt) {
    let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved,);
}

@view
func getPoints{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (points: Uint256) {
    alloc_locals;
    let account = (tokenId.high * 0x100000000000000000000000000000000) + tokenId.low;
    let (points) = IPointsContract.balanceOf(
        contract_address=POINTS_CONTRACT, 
        account=account
    );
    return (points=points);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (tokenURI_len: felt, tokenURI: felt*) {
    alloc_locals;
    let (points) = getPoints(tokenId);
    let (progress) = get_progress(points);
    let (svg) = create_tokenURI(seed=tokenId.low, progress=progress);
    return (tokenURI_len=svg.arr_len, tokenURI=svg.arr);
}

@view
func avatarData{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (
    rows: felt, 
    cols: felt, 
    padding: felt, 
    scale: felt, 
    dimension: felt, 
    points: Uint256,
    fingerprint: felt,
) {
    alloc_locals;

    let (points) = getPoints(tokenId);
    let (progress) = get_progress(points);
    let (rows, cols, padding, scale, dimension, fingerprint) = create_data(seed=tokenId.low, progress=progress);
    return(
        rows=rows, 
        cols=cols, 
        padding=padding, 
        scale=scale, 
        dimension=dimension,
        points=points,
        fingerprint=fingerprint
    );
}

@view
func paused{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (paused: felt) {
    let (paused) = Pausable.is_paused();
    return (paused,);
}

@view
func implementation{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (implementation: felt) {
    return Proxy.get_implementation_hash();
}

//
// Externals
//

@external
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    Pausable.assert_not_paused();
    ERC721.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    Pausable.assert_not_paused();
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    with_attr error_message("Soulbound NFT cannot be transferred") {
        assert 0 = 1;
    }
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    with_attr error_message("Soulbound NFT cannot be transferred") {
        assert 0 = 1;
    }
    return ();
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    Pausable.assert_not_paused();
    Ownable.assert_only_owner();
    ERC721._mint(to, tokenId);
    return ();
}

@external
func pause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.assert_only_owner();
    Pausable._pause();
    return ();
}

@external
func unpause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.assert_only_owner();
    Pausable._unpause();
    return ();
}

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(implementation);
    return ();
}