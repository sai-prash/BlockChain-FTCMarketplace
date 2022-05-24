pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract FantasyEPLToken is ERC20{
    
    address creator;

    address allowedMarketPlace;

    constructor(string memory name_, string memory symbol_, uint supply) ERC20(name_, symbol_) {
       creator = msg.sender;
       _mint(msg.sender, supply * (10 ** decimals()));
    }

    //Only MarketPlace
    modifier onlyMarketPlace(){
        require(msg.sender == allowedMarketPlace);
        _;
    }

    //Only Owner
    modifier onlyOwner(){
        require(msg.sender == creator);
        _;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        //address owner = _msgSender();
        _approve(spender, allowedMarketPlace, amount);
        return true;
    }

    function setAllowedMarketPlace(address _allowedMarketPlace) public onlyOwner{
        allowedMarketPlace = _allowedMarketPlace;
    }
    
    function getAllowedMarketPlace() public view onlyMarketPlace returns(address){
        return allowedMarketPlace;
    }

}   