pragma solidity ^0.4.21;



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}


 

contract GoldenCurrencyToken is BurnableToken {
  string public constant name = "Pre-ICO Golden Currency Token v7";
  string public constant symbol = "PGCT";
  uint32 public constant decimals = 18;
  uint256 public INITIAL_SUPPLY = 7600000 * 1 ether;

  function GoldenCurrencyToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;      

  }
  

}
  
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
 contract Ownable {
  address public owner;
  address public candidate;
  address public manager;

  function Ownable() public {
    owner = msg.sender;
    manager = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyManagment() {
    require(msg.sender == owner || msg.sender == manager);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    candidate = newOwner;
  }

  function confirmOwnership() public {
    require(candidate == msg.sender);
    owner = candidate;
    delete candidate;
  }

  function transferManagment(address newManager) public onlyOwner {
    require(newManager != address(0));
    manager = newManager;
  }
}

  


contract Crowdsale is Ownable {
  using SafeMath for uint;    
  address myAddress = this;    

    address profitOwner = 0xdd870fa1b7c4700f2bd7f44238821c26f7392148; //адрес, на который будут пересылаться средства (эфир)
    uint public  rate = 500;
    uint start = 1523450379; //StartTime 16.04.2018 - 1523836800
    uint finish = 1531785599; //FinishTime  16.07.2018 23:59 - 1531785599
    uint256 period1 = 1523836800;   //        16 апреля 00:00 - 1523836800
    uint256 period2 = 1525132800;   //        1 мая 00:00     - 1525132800
    uint256 period3 = 1527811200;   //        1 июня 00:00    - 1527811200
  
  event TokenRates(uint256 indexed value);

  GoldenCurrencyToken public token = new GoldenCurrencyToken();
  
    modifier saleIsOn() {
        require(now > start && now < finish);
        _;
    }

    function setProfitOwner (address _newProfitOwner) public onlyOwner {
        require(_newProfitOwner != address(0));
        profitOwner = _newProfitOwner;
    }

    function SaleTokens(address _newInvestor, uint256 _value) public saleIsOn onlyManagment payable {
        // ф-ия продажи токенов за фиат новым инвесторам
        // сумма вводится в целых токенах (1 = 1 токен)
        require (_newInvestor!= address(0));
        require (_value >= 1);
        _value = _value.mul(1 ether);
        token.transfer(_newInvestor, _value);
    }    
    
    
    

    
    function userTransferToken(address _Recipient, uint256 _value) public saleIsOn payable {
        // общедоступная ф-ия перевода собственных токенов по указанному адресу
        // Сумма вводится в целых токенах. 1=1 токен
        require (_Recipient!= address(0));
        require (_value >= 1 && _value < 7600000 * 1 ether);
        _value = _value.mul(1 ether);
        token.transfer (_Recipient, _value);
        
    }
  
  
  /*
  1523450379, 1523836800, 1525132800, 1527811200, 1531785599        //начались продажи - скидка 25 %
  1523450379, 1523450380, 1523450381, 1527811200, 1531785599        // попали во второй период - скидка 20%
  1523450379, 1523450380, 1523450381, 1523450382, 1531785599        // попали во третий период - скидка 15%
  
  
  */
    function createTokens() saleIsOn internal {

    profitOwner.transfer(msg.value);
    uint tokens = rate.mul(msg.value);
    require (tokens.div(1 ether) >= 100);  //минимум 100 токенов покупка
    uint bonusTokens = 0;
        /*
        скидка 25% с 16 по 30 апреля 2018 года
        скидка 20% с 1 по 31 мая 2018 года
        скидка 15% с 1 июня по 16 июля 2018 года
        16 апреля 00:00 - 1523836800
        30 апреля 23:59 - 1525132799
        1 мая 00:00     - 1525132800
        31 мая 23:59    - 1527811199
        1 июня 00:00    - 1527811200
        16 июля 23:59   - 1531785599
        */



    if(now < period2) {
      bonusTokens = tokens.div(4);
    } else if(now >= period2 && now < period3) {
      bonusTokens = tokens.div(5);
    } else if(now >= period3 && now < finish) {
      bonusTokens = tokens.div(100).mul(15);
    }

    uint tokensWithBonus = tokens.add(bonusTokens);
    token.transfer(msg.sender, tokensWithBonus);
  }
 
 
   function setTokenRate(uint newRate) public onlyManagment {
      rate = newRate;
      emit TokenRates(newRate);
  }
   
  function changePeriods(uint256 _start, uint256 _period1, uint256 _period2, uint256 _period3, uint256 _finish) public onlyOwner {
    start = _start;
    finish = _finish;
    period1 = _period1;
    period2 = _period2;
    period3 = _period3;
  }
  

 
  function() external payable {
    createTokens();
  }    
 
 
}