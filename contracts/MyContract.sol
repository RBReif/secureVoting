pragma solidity ^0.8.0;

contract MyContract {
    uint value = 1;
    uint value2 = 4;
    uint value3 =5;

    function get() public view returns (uint){
        return value;
    }

    function double() public{
        value *=2;
    }
}