var FantasyLeague = artifacts.require("./FantasyLeague.sol");
var FantasyEPLToken = artifacts.require("./FantasyEPLToken.sol");

module.exports = async function(deployer) {
  await deployer.deploy(FantasyEPLToken, "FantasyEPL", "EPL", "10000");
  const fantasyEPLTokenInstance = await FantasyEPLToken.deployed();
  
  await deployer.deploy(FantasyLeague, fantasyEPLTokenInstance.address);
  const fantasyLeagueInstance = await FantasyLeague.deployed();

  await fantasyEPLTokenInstance.setAllowedMarketPlace(fantasyLeagueInstance.address);
}
