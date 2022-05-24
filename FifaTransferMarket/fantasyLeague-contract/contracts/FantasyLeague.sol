pragma solidity ^0.8.0;

import "./FantasyEPLToken.sol";

contract FantasyLeague{
    address payable owner;

    FantasyEPLToken token;

    constructor(address _token){
        owner = payable(msg.sender);
        addTeam(owner, 'Team1');
        token = FantasyEPLToken(_token);
    }

    //Only Owner
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function getOwner() public view returns(address){
       return owner;
    }


    function getAllowedMarketPlace() public view returns(address){
        return token.getAllowedMarketPlace();
    }

    function getTokenBalance() public view returns(string memory){
        return toString(token.balanceOf(msg.sender));
    }

    //Strcuture for Teams 
    //Each User who are authorized to buy and sell is a Team
    struct Teams{
        uint id;
        string name;
        uint[] ownedPlayers;
    }

    uint teamsCount = 0;
    //List of Participating Teams
    mapping(address => Teams) public teams;

    function addTeam(address teamAddress, string memory _name) public onlyOwner{
        uint[] memory ownedPlayers;
        teams[teamAddress] = Teams(teamsCount+1, _name, ownedPlayers);
        teamsCount = teamsCount + 1;
    }

    function assignPlayersToTeam(address payable teamAddress, uint playerID) public onlyOwner{
        checkIfTeamRegistered(teamAddress);
        teams[teamAddress].ownedPlayers.push(playerID);
        players[playerID].ownedBy = teamAddress;
    }

    struct Player{
        uint id;
        string name;
        uint price;
        bool is_sellable;
        address payable ownedBy;
    }

    uint public playersCount = 0;

    mapping(uint => Player) players;
    
    function checkIfTeamRegistered(address teamAddress) internal view{
        if(teams[teamAddress].id == 0){
            revert("Team Not Registered - Contact Owner");
        }
    }

    function checkIfPlayerIsInTeam(address teamAddress, uint playerID) internal view{
        checkIfTeamRegistered(teamAddress);
        checkIfPlayerExist(playerID);
        Teams memory team = teams[teamAddress];
        
        bool playerPresentInTeam = false;
        for(uint i = 0; i < team.ownedPlayers.length; i++){
            if(team.ownedPlayers[i] == playerID){
                playerPresentInTeam = true;
            }
        }

        if(!playerPresentInTeam){
            revert("Player is not Owned by the Team");
        }
        
    }

    function checkIfPlayerExist(uint playerID) internal view{
        if(playerID >= playersCount){
            revert("Player Not Present");
        }
    }

    function addPlayer(string memory name, uint price, bool is_sellable) public onlyOwner{   
        players[playersCount] = Player(playersCount, name, price, is_sellable, owner);
        assignPlayersToTeam(owner, playersCount);
        playersCount = playersCount + 1;
    }

    function setPlayerPrice(uint playerID, uint price) public{
        checkIfPlayerIsInTeam(msg.sender, playerID);
        players[playerID].price = price;
    }

    function togglePlayerSellable(uint playerID) public{
        checkIfPlayerIsInTeam(msg.sender, playerID);
        players[playerID].is_sellable = !players[playerID].is_sellable;
    }

    function checkIfPlayerSellable(uint playerID) internal view returns(bool){
        checkIfPlayerExist(playerID);
        if(!players[playerID].is_sellable){
            revert("Player Not Sellable");
        }
        return players[playerID].is_sellable;
    }

    function checkTokenBeforePurchase(uint amount) internal view{
        if(amount > token.balanceOf(msg.sender)){
            revert("Not Enough Tokens");
        }
    }

    function sendToken(address to, uint amount) public{
        token.approve(msg.sender,amount);
        token.transferFrom(msg.sender, to, amount);
    }

    function buyPlayer(uint playerID, uint amount) public payable{
        checkIfPlayerExist(playerID);
        checkifPlayerAlreadyOwned(playerID);
        //checkIfPlayerIsInTeam(msg.sender, playerID);
        checkIfPlayerSellable(playerID);

        Player memory player = players[playerID];

        address payable seller = player.ownedBy;
        // uint amount;
        // amount = msg.value;
        uint price;
        price = player.price;
        if (amount != price){
            revert("Mismatch price");
        }

        checkTokenBeforePurchase(amount);

        sendToken(seller, amount);
        //seller.transfer(msg.value);

        if(seller != owner){
            //owner.transfer(price/10);
            removePlayerFromSeller(playerID, seller);
        }

        addPlayerToSelf(playerID);

        
    }
    function checkifPlayerAlreadyOwned(uint playerID) internal view{
        Player storage player = players[playerID];
        if (player.ownedBy == (msg.sender)){
            revert("Already owned");
        }
    }
    function addPlayerToSelf(uint playerID) internal {
        Player storage player = players[playerID];
        player.ownedBy = payable(msg.sender);
        teams[msg.sender].ownedPlayers.push(playerID);
    }

    function removePlayerFromSeller(uint playerID, address payable seller) internal {
        
        uint[] memory ownedPlayers = teams[seller].ownedPlayers;
        uint[] memory updatedOwnedPlayers;
        teams[seller].ownedPlayers = updatedOwnedPlayers;

        for(uint i = 0; i < ownedPlayers.length; i++){
            if(ownedPlayers[i] != playerID){
                teams[seller].ownedPlayers.push(ownedPlayers[i]);
            }
        }

    }

    function getMyPlayersCount() public view returns(string memory){
        return toString(teams[msg.sender].ownedPlayers.length);
    }

    function checkMyPlayerIndex(uint index) internal view returns(bool){
        checkIfTeamRegistered(msg.sender);
        if(index >= teams[msg.sender].ownedPlayers.length){
            return false;
        }
        return true;
    }

    function getMyPlayer(uint index) public view returns(string memory, string memory, string memory, bool){
        checkIfTeamRegistered(msg.sender);
        require(checkMyPlayerIndex(index), "Searching Player not Available");
        
        Player memory player = players[teams[msg.sender].ownedPlayers[index]];
        return (toString(player.id), player.name, toString(player.price), player.is_sellable);
    }

    function getAllPlayersCount() public view returns(string memory){
        return toString(playersCount);
    }

    function getPlayer(uint index) public view returns(string memory, string memory, string memory, bool, address){
        Player memory player = players[index];
        return (toString(player.id), player.name, toString(player.price), player.is_sellable, player.ownedBy);
    }

    function checkIfTeamExist() external view returns(bool){
        if(teams[msg.sender].id == 0){
            return false;
        }
        return true;
    }

    function getMyTeamDetails() public view returns(uint, string memory){
        checkIfTeamRegistered(msg.sender);
        Teams memory myTeam = teams[msg.sender];
        return (myTeam.id, myTeam.name);
    }

     function toString(uint256 value) internal pure returns (string memory) {
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}