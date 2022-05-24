App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',
  Owner: '0x0',
  fantasyLeagueInstance:null,
  //fantasyEPLTokenInstance:null,

  init: function() {
    return App.initWeb3();
  },

  initWeb3: function() {
    if (typeof web3 !== 'undefined') {
      App.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
      
      
    } else {
      App.web3Provider = new Web3.providers.HttpProvider('https://ropsten.infura.io/v3/bb199b080d9146b9ba0dd802a4931909');
      web3 = new Web3(App.web3Provider);
    }
    web3.eth.defaultAccount=web3.eth.coinbase;

    // window.ethereum.on('accountsChanged', function (accounts) {
    //   location.reload();
    // })
    return App.initContract();
  },

  initContract: function() {
    
    $.getJSON("FantasyLeague.json", function(fantasyLeague) {
      
      //window.ethereum.enable();
      App.contracts.FantasyLeague = TruffleContract(fantasyLeague);
      App.contracts.FantasyLeague.setProvider(App.web3Provider);


      App.contracts.FantasyLeague.deployed().then(function(instance) {
        App.fantasyLeagueInstance = instance;
        return App.fantasyLeagueInstance.getOwner();
      }).then(function(owner) {
        App.Owner = owner;
        App.checkIfTeamRegistered();
      }).catch(function(error) {
       console.warn(error);
      });
    });
    
    web3.eth.getCoinbase(function(err, account) {
      console.log(web3.eth);
      console.log("Account", account);
      if (err === null) {
        App.account = account;
        $("#accountAddress").html("Your Account: " + account);
      }
    });
  },
  
  loadPlayers  : function(){
    App.fantasyLeagueInstance.getAllPlayersCount().then(function(playersCount){
      for(let i = 0; i < playersCount; i++){
        App.fantasyLeagueInstance.getPlayer(i).then(renderPlayer);
      }
    });
  },

  loadTeamDetails : function(){
    App.fantasyLeagueInstance.getMyTeamDetails().then(setTeamDetails);
    App.fantasyLeagueInstance.getTokenBalance().then(setTokenBalance);
    setAccountBalance();
  },

  renderOwnerFunctionalities : function(){
    jQuery("#owner-div").removeClass("hidden");
  },

  checkIfTeamRegistered : function(){
    App.fantasyLeagueInstance.checkIfTeamExist().then(function(isTeamRegistered){
      if(isTeamRegistered){
        App.renderPage();
      }
      else{
        alert("Team Not Registered");
      }
    });
  },

  renderPage: function() {
    if(App.Owner == App.account){
      App.renderOwnerFunctionalities();
      document.querySelector("#air-drop-container").style.visibility = "visible";
    }else{
      node = document.querySelector("#air-drop-container");
      node.parentElement.removeChild(node);
    }
    App.loadPlayers();
    App.loadTeamDetails();
  },

  addPlayer : function(){
    let playerName = jQuery('#player-name').val();
    let playerPrice = web3.toWei(jQuery('#player-price').val(), "ether");
    App.fantasyLeagueInstance.addPlayer(playerName, playerPrice, true).then(function(){
      alert("Player Added Successfully");``
      location.reload();
    });
  },

  addTeam : function(){
    let teamName = jQuery('#team-name').val();
    let teamAddress = jQuery('#team-address').val();
    App.fantasyLeagueInstance.addTeam(teamAddress, teamName).then(function(){
      alert("Team Added Successfully");
    });
  },

  buyPlayer : function(id, price){
    App.contracts.FantasyLeague.deployed().then(function(instance){
      return instance.buyPlayer(id, web3.toWei(price, "ether"), {gas: 3000000});
    }).then(function(result){
      console.log(result);
      location.reload();
    }).catch(function(error) {
      console.warn(error);
      location.reload();
    });
  },
  changeSellable : function(id){
    App.contracts.FantasyLeague.deployed().then(function(instance){
      return instance.togglePlayerSellable(id, {gas: 3000000});
    }).then(function(result){
      console.log(result);
      location.reload();
    }).catch(function(error) {
      console.warn(error);
    });
  },

  updatePrice : function(id, event){
    console.log("aaaaaaaa", id, event.keyCode  );
    if (event.keyCode !=13){
      return;
    }
    //console.log(event)
    
    let price = document.querySelector("#price"+id).value;
    console.log(price);
    App.contracts.FantasyLeague.deployed().then(function(instance){
      return instance.setPlayerPrice(id, web3.toWei(price, "ether"), {gas: 3000000});
    }).then(function(result){
      console.log(result);
      //location.reload();
    }).catch(function(error) {
      console.warn(error);
    });
  },

  addAirDrop : function(){
    let account_address = jQuery("#send-token-to").val();
    let tokens_count = parseInt(jQuery("#send-token-count").val());
    App.fantasyLeagueInstance.sendToken(account_address, web3.toWei(tokens_count, "ether")).then(function(){
      alert("Token Sent Successfully");
      location.reload();
    });
  }

};


function renderPlayer(playerDetails){
  let id =  playerDetails[0];
  let name = playerDetails[1];
  let price = web3.fromWei(playerDetails[2] , 'ether');
  let is_sellable = playerDetails[3];
  let ownedBy = playerDetails[4];

  let is_own_player = ownedBy == App.account

  let $parentDiv = is_own_player ? jQuery("#myPlayersList") : jQuery("#otherPlayersList");

  let $playerDiv = jQuery("<div class='player-details'></div>");
  let $name = jQuery("<div><div>Name:</div><div> "+ name +"</div></div>");
  let $id = jQuery("<div><div>Id: </div><div>"+ id +"</div></div>");
  let $price = jQuery("<div><div>Price(EPL token): </div><input contenteditable=true id=price"+id+" onkeyup=\"App.updatePrice(" + id +",event)\" value="+price+"></input></div>");

  $playerDiv.append($name);
  $playerDiv.append($id);
  $playerDiv.append($price);
  
  if(is_own_player){
    $playerDiv.append(jQuery("<div>Sellable <label class=\"switch\"><input id=sellableChkBox"+id+" type=\"checkbox\" checked="+is_sellable+" onclick=\"App.changeSellable("+id+")\"><span class=\"slider round\"></span></label> </div>"));
  
  }
  else{
    $playerDiv.append(handleBuy(is_sellable, price, id));
  }

  $parentDiv.append($playerDiv);
  //todo change
  if(document.querySelector("#sellableChkBox"+id)){
    document.querySelector("#sellableChkBox"+id).checked= is_sellable;
  }
  
}

function handleBuy(is_sellable, price, id){
  if(is_sellable){
    
    return jQuery("<button class='button-17' role='button' playerID="+ id +" onclick='App.buyPlayer(" +id+", "+ price+")'\>Buy Player</button>");  
  }
  else{
    return jQuery("<div>Player Not Available for purchase</div>");
  }
}

function setTeamDetails(teamDetails){
  jQuery(".team-name").html(teamDetails[1]);
}

function setTokenBalance(balance){
  let token_balance = "<b>Token Balance(EPL): </b>" + web3.fromWei(balance, "ether");
  jQuery(".team-token-balance").html(token_balance);
}

function setAccountBalance(){
  web3.eth.getBalance(App.account, function(err, result) {
    if (err) {
      console.log(err)
    } else {
      let balance = "<b>Balance(Eth): </b>" + web3.fromWei(result, "ether");
      jQuery(".team-balance").html(balance);
    }
  });
}

$(function() {
  $(window).load(function() {
    App.init();
  });
});