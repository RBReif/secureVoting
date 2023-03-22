//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

//StorageFactory and SimpleStorage in same folder 
//import SimpleStorage
import "./SimpleStorage.sol";

contract StorageFactory is SimpleStorage{ //inheritance

    SimpleStorage[] public simpleStorageArray; //stores address of stored contracts



    function createSimpleStorageContract() public {
        SimpleStorage simpleStorage = new SimpleStorage();
        simpleStorageArray.push(simpleStorage);
    }

    function sfStore(uint256 _simpleStorageIndex, uint256 _simpleStorageNumber) public{
        //address  -> lookup in array above
        //abi  -> application binary interface  -> look into import

        SimpleStorage simpSto = SimpleStorage(address(simpleStorageArray[_simpleStorageIndex]));
        simpSto.store(_simpleStorageNumber);
    }

    function sfGet(uint256 _simpleStorageIndex) public view returns (uint256){
        SimpleStorage simpSto = SimpleStorage(address(simpleStorageArray[_simpleStorageIndex]));
        return simpSto.retrieve();
    }

}