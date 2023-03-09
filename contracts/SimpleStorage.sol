// SPDX-Licensce Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
    uint256 favoriteNumber = 5; 
    bool favoriteBool = false;
    string favoriteString = "String";
    int256 favoriteInt= -5;
    address  favoriteAddress = 0xb2998c5Fb14e2253D4Fe3a7381833121F278B52f;
    bytes32  favoriteBytes = "cat";
    //comment

    struct People{
        uint256 favoriteNumber;
        string name; 
    }

    People public person = People({favoriteNumber:3, name:"Patrick"});

    People[] public people; //fixed size [49] or dynamic [] possible

    function addPerson(string memory _name, uint256 _favoriteNumber) public{
        //memory: only be stored during execution/function call
        //storage: will consist afterwards

        //string: actually an array of bytes (an object type) => we need to specify where to store it


        //push: adding to Array
        //next line equals: people.push(People({favoriteNumber: _favoriteNumber, name: _name}));
        people.push(People(_favoriteNumber,_name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }


    function store(uint256 _favoriteNumber) public{
        favoriteNumber=_favoriteNumber;
       // uint256 test = 4;
    }
    //public: can be called by anyone
    //external: can't be called by contract itself, only from outside
    //internal: only from inside the contract (or derived contracts)
    //private: only from this contract

    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }
     //view: just reading
     //pure: just doing some kind of math, without saving it

     
     //mapping

     mapping(string => uint256) public nameToFavoriteNumber;





}