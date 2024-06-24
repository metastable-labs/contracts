pragma solidity 0.8.24;

contract MockPair {
    address private _token0;
    address private _token1;
    uint112 private _reserves0;
    uint112 private _reserves1;

    constructor(address __token0, address __token1, uint112 __reserves0, uint112 __reserves1) {
        _token0 = __token0;
        _token1 = __token1;
        _reserves0 = __reserves0;
        _reserves1 = __reserves1;
    }

    function token0() external view returns (address) {
        return _token0;
    }

    function token1() external view returns (address) {
        return _token1;
    }

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        return (_reserves0, _reserves1, uint32(block.timestamp));
    }
}
