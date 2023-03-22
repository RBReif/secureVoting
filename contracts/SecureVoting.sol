// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12; //support arrays of strings
import "@openzeppelin/contracts/utils/Strings.sol";


contract PartyConvention {

    /*

            ConventionRoles
    GUEST:                  can see the results of Motions
    MEMBER:                 can create regular motions, can initially support regular motions
    REPLACEMENTDELEEGATE:   can hold votingRights, can transfer votingRights, can requestVotingRightsBack, can vote
    DELEGATE:               gets votingRight after being added
    ADMIN:                  can add/modify/delete participants, can add PERSON motions/elections, can open person motions/elections, can close motions

    Every role includes the rights of lesser roles.

            MotionTypes
    REGULAR:                Regular Motions can receive "yes"/"no"/"abstain" votes. To be passed, they need to receive a relative majority (more "yes" votes than "no" votes). Per voting right one can choose either "yes", "no", or "abstain".
    PERSON:                 For elections of persons to party offices a candidate needs to get an absolute majority (more than 50% of all voting rights, that were exercised in this Motion/Election). Per voting right, a voter might be allowed to vote for multiple candidates at the same time              
   
    */

    enum ConventionRole{GUEST, MEMBER, REPLACEMENTDELEGATE, DELEGATE, ADMIN} 
    enum MotionStatus{PREPARED, OPEN, CLOSED}
    enum MotionType{REGULAR, PERSON }
    
    uint public motionCounter = 0;
    uint public votingRightsCounter = 0;

    mapping(address => Participant) public participants;
    address[] participantsArray;

    Motion[]  motions;

//##################################################################################################################
//########################################### All Objects/Classes/Structs ##########################################
   
    struct Participant {
        ConventionRole role;
        address votingRight1from;
        address votingRight2from;
    }

    struct Option{ //a motion consists of options. The name of an option can be e.g. "yes", "no", "abstain", "candidate 1", candidate 2", etc.
        string text;
        uint voteCount;
    }

    struct Motion{
        uint id;
        string text;    //text is what will be voted on. Eg. "Who should be elected as new chairperson?", "are you in favor of motion xyz?"
        MotionType mtype;
        MotionStatus status;
        Option[]  options;
        address[] voters; 
        address[] initialSupporters; //10 Delegates or 30 Members are needed as supporters for a motion to be called to a vote
        }



//##################################################################################################################
//########################################### Constructor ##########################################################


    constructor(){
        Participant memory creator;
        creator.role=ConventionRole.ADMIN;
        creator.votingRight1from=msg.sender;
        participants[msg.sender] = creator;
        participantsArray.push(msg.sender);
        votingRightsCounter++;
    }
    
    
  

//##################################################################################################################
//############################## Internal Helper Functions #########################################################

    function append( string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) { //this function is oriented at https://ethereum.stackexchange.com/questions/729/how-to-concatenate-strings-in-solidity
    return string(abi.encodePacked(a, b, c, d,e));
    }

    function noOpenMotions() internal view returns (bool){
        for (uint i=0; i<motions.length;i++ ){
            if (motions[i].status == MotionStatus.OPEN){
                return false;
            }
        }
        return true;
    }

    function notContainedInArray(address[] memory arr_, address el_) pure internal returns (bool){
        for (uint i=0; i<arr_.length;i++ ){
            if (arr_[i] == el_){
                return false;
            }
        }
        return true;
    }

    function transfer(address fromwhom_, address towhom_, uint which_) internal{
        require(which_==1 || which_==2);

           if(participants[towhom_].votingRight1from == address(0)){
            participants[towhom_].votingRight1from = fromwhom_;
        } else{
            participants[towhom_].votingRight2from = fromwhom_;
        }
        if(which_==1){
        participants[fromwhom_].votingRight1from = address(0);
        }
    }

        function enoughSupporters(uint id_) view internal returns (bool){
        uint  delegates = 0;
        uint  members = 0;

        for (uint i=0; i<motions[id_].initialSupporters.length;i++ ){
            if (participants[motions[id_].initialSupporters[i]].role >= ConventionRole.DELEGATE){
               delegates++;
            }
            members++;
        }
        return delegates>=10 || members >=30;

    }


//##################################################################################################################
//####################################### Public Functions #########################################################

//ADMIN Level

    function addParticipant(ConventionRole role_, address addr_ ) external {
        require(participants[msg.sender].role == ConventionRole.ADMIN, "Only admins can add new convention participants."); 
        require(participants[addr_].votingRight1from==address(0) && participants[addr_].votingRight2from==address(0), "The Participant was already added and holds voting rights." );
        require(noOpenMotions(), "Can not add new participants while voting is going on.");

        Participant memory newParticipant;
        newParticipant.role = role_;
        if (role_ == ConventionRole.DELEGATE || role_ == ConventionRole.ADMIN){
            newParticipant.votingRight1from =addr_;
            votingRightsCounter++;
        }
        participants[addr_]  = newParticipant;
        participantsArray.push(addr_);
        
    }

    function closeMotion(uint id_) external{
        require(participants[msg.sender].role == ConventionRole.ADMIN, "Only admins can close motions."); 
        require(motions[id_].status==MotionStatus.OPEN, "Only open motions can be closed.");
        motions[id_].status = MotionStatus.CLOSED;
    }


//DELEGATE Level


    function reclaimOriginalVotingRight() public returns(bool){
        require(participants[msg.sender].role >=ConventionRole.DELEGATE, "Only delegates can reclaim their original voting right.");
        require(participants[msg.sender].votingRight1from == address(0) || participants[msg.sender].votingRight2from == address(0), "Reclaimer already holds 2 active voting rights");
        require(participants[msg.sender].votingRight1from != msg.sender && participants[msg.sender].votingRight2from != msg.sender, "Reclaimer already holds his/her original voting right");

        for (uint i=0; i< participantsArray.length;i++){
            if(participants[participantsArray[i]].votingRight1from==msg.sender){
                transfer(participantsArray[i],msg.sender,1);
                return true;
            }
            if(participants[participantsArray[i]].votingRight2from==msg.sender){
                transfer(participantsArray[i],msg.sender,2);
                return true;
            }
        }
        return false;
    }

//(REPLACEMENT)DELEGATE Level

    function voteForMotion(uint motionid_, uint optionid_) public{
        require(participants[msg.sender].role >=ConventionRole.REPLACEMENTDELEGATE, "Only (replacement)delegates can cast votes.");
        require(motions[motionid_].status == MotionStatus.OPEN, "Motion is not open for voting.");
        require(participants[msg.sender].votingRight1from!=address(0) || participants[msg.sender].votingRight2from!=address(0), "No active voting rights held by sender");
        require(participants[msg.sender].votingRight1from!=address(0) && notContainedInArray(motions[motionid_].voters, participants[msg.sender].votingRight1from) 
             || participants[msg.sender].votingRight2from!=address(0) && notContainedInArray(motions[motionid_].voters, participants[msg.sender].votingRight2from), "Vote(s) were already cast");

        if(participants[msg.sender].votingRight1from!=address(0) && notContainedInArray(motions[motionid_].voters, participants[msg.sender].votingRight1from)){
            motions[motionid_].voters.push(participants[msg.sender].votingRight1from);
            motions[motionid_].options[optionid_].voteCount++;
        }

        if(participants[msg.sender].votingRight2from!=address(0) && notContainedInArray(motions[motionid_].voters, participants[msg.sender].votingRight2from)){
            motions[motionid_].voters.push(participants[msg.sender].votingRight2from);
            motions[motionid_].options[optionid_].voteCount++;
        }

        if(motions[motionid_].voters.length >= votingRightsCounter){ // everyone has voted
            motions[motionid_].status=MotionStatus.CLOSED;
        }

    }

    function transferVotingRight1(address towhom_) public{
        require(participants[msg.sender].role >=ConventionRole.REPLACEMENTDELEGATE, "Only (replacement)delegates can transfer voting rights.");
        require(participants[towhom_].role >=ConventionRole.REPLACEMENTDELEGATE, "Only (replacement)delegates can receive voting rights.");

        require(participants[msg.sender].votingRight1from != address(0), "Message sender does not hold any voting right 1.");
        require(participants[towhom_].votingRight1from == address(0) || participants[towhom_].votingRight2from == address(0), "Receiving (replacement)delegate has already 2 active voting rights");

        require(noOpenMotions(), "Can not transfer votes during open voting processes");

        transfer(msg.sender,towhom_, 1);
       
    }

//MEMBER Level

    function createRegularMotion(string memory txt_) external returns (uint){
        require(participants[msg.sender].role >=ConventionRole.MEMBER, "Only party members can create a regular motion.");
        require(noOpenMotions(), "Can not create new motions while voting is going on.");
       
        Motion storage m =  motions.push();
        m.id = motionCounter;
        m.text = txt_;
        m.mtype = MotionType.REGULAR;
        m.status = MotionStatus.PREPARED;

        Option storage o1 = m.options.push();
        o1.text = "yes";
        o1.voteCount = 0;

        Option storage o2 = m.options.push();
        o2.text = "no";
        o2.voteCount = 0;

        Option storage o3 = m.options.push();
        o3.text = "abstain";
        o3.voteCount = 0;

        m.initialSupporters.push(msg.sender);
      
        motionCounter++;
        return m.id;
    }




    function initiallySupportMotion(uint id_) public{
        require(participants[msg.sender].role >=ConventionRole.MEMBER, "Only party members can initially support a regular motion.");
        require(notContainedInArray(motions[id_].initialSupporters,msg.sender), "A member can only once support a regular motion initially."); //Note: a transferred voting Right does not transfer the right to initially support a motion
        motions[id_].initialSupporters.push(msg.sender); //The sender is added as a new supporter
        if (enoughSupporters(id_)){
            motions[id_].status=MotionStatus.OPEN; // If one of the thressholds is reached for the motion, the voting regarding the motion can start.
        }
    }


   
//GUEST Level

    function seeResults(uint motionid_) view public returns(string memory result){
        require(motions[motionid_].status == MotionStatus.CLOSED, "Motion is not closed yet.");
        result = "";
        for (uint i =0; i < motions[motionid_].options.length;i++){
            string memory count = Strings.toString(motions[motionid_].options[i].voteCount);
            result = append(result, motions[motionid_].options[i].text, ":",count,"." );
        }
        return result;

    }









}