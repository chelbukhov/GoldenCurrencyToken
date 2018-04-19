pragma solidity ^0.4.21;
//0x064Dab03B7ea9fAC967fA43d2aE2F55d5436f950

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


contract GoldenCurrency {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 public totalSupply;
    uint256 public releaseTime; //StartTime 16.04.2018 - 1523836800
    uint256 public closeTime; //FinishTime  16.07.2018 - 1531699200
    address public owner;
    address public candidate;
    address public manager;
    

    string public constant name = "Pre-ICO Golden Currency Token"; // solium-disable-line uppercase
    string public constant symbol = "PGCT"; // solium-disable-line uppercase
    uint8 public constant decimals = 18; // solium-disable-line uppercase
    uint256 public constant INITIAL_SUPPLY = 5000000 * (10 ** uint256(decimals)); // 5 mln
    uint256 public tokenRate; //курс токена (доллара) к эфиру

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WithdrowTokens(address indexed to, uint256 value);
    event Investor(address indexed from, uint256 value);
    event TokenRates(uint256 indexed value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier restricted() {
        require(msg.sender == owner || msg.sender == manager);
        _;
    }

    modifier timePreICO() {
        require(releaseTime < block.timestamp);
        require(closeTime > block.timestamp);
        _;
    }

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
    function GoldenCurrency() public {
        owner = msg.sender;
        manager = msg.sender;
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        tokenRate = 500; //курс токена (доллара) к эфиру
        releaseTime = 1523377787; //!!!!!Заменить на StartTime 16.04.2018 00:00 - 1523836800
        closeTime = 1531785599; //FinishTime  16.07.2018 23:59 - 1531785599

    }

/*
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
*/


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        candidate = newOwner;
    }

    function confirmOwnership() public {
        require(candidate == msg.sender);
        owner = candidate;
        delete candidate;
        emit OwnershipTransferred(owner, candidate);
    }

    function transferManagment(address newManager) public onlyOwner {
        require(newManager != address(0));
        manager = newManager;
    }

    function SetTokenRate(uint256 newRate) public restricted {
        tokenRate = newRate; //изменение курса токена к эфиру
        emit TokenRates(newRate);
    }

    function CalcBonus () internal view returns (uint8) {
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
        uint256 currentTime = block.timestamp;
        uint8 actualBonus = 100; // %
        if (currentTime > 1523836800 && currentTime < 1525132799) {
            actualBonus = 75;
        }
        if (currentTime > 1525132800 && currentTime < 1527811199) {
            actualBonus = 80;
        }
        if (currentTime > 1527811200 && currentTime < 1531785599) {
            actualBonus = 85;
        }
        return actualBonus;
    }


    function withdrowTokens(address _to, uint256 _value) public restricted returns (bool) {
        require(_to != address(0));
        address myAddress = this;
        require(_value <= balances[myAddress]);

        balances[myAddress] = balances[myAddress].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit WithdrowTokens(_to, _value);
        return true;
    }


    function BuyTokens () public payable timePreICO {
        //отправка токенов по адресу отправителя
        require(msg.sender != address(0));
        require(msg.value > 0);
        address myAddress = this;
        uint256 addValue = tokenRate.mul(msg.value);
        addValue = addValue.mul(100);                   //100%
        addValue = addValue.div(uint256(CalcBonus()));  //% со скидкой
        assert(addValue >= 100);                        // минимальная сумма покупки 100 токенов
        balances[myAddress] = balances[myAddress].sub(addValue);
        balances[msg.sender] = balances[msg.sender].add(addValue);
        emit Investor(msg.sender, addValue);
    }

    function () public payable timePreICO {
        //отправка токенов по адресу отправителя
        require(msg.sender != address(0));
        require(msg.value > 0);
        address myAddress = this;
        uint256 addValue = tokenRate.mul(msg.value);
        addValue = addValue.mul(100);                   //100%
        addValue = addValue.div(uint256(CalcBonus()));  //% со скидкой
        assert(addValue >= 100);                        // минимальная сумма покупки 100 токенов
        balances[myAddress] = balances[myAddress].sub(addValue);
        balances[msg.sender] = balances[msg.sender].add(addValue);
        emit Investor(msg.sender, addValue);
    }
   
    function getBalance () public view returns (uint256) {
        address myAddress = this;
        return balances[myAddress];
    }
   
    function setBalance () public onlyOwner{
        address myAddress = this;
        balances[myAddress] = balances[myAddress].add(5000000 * 10**18);
    }
}

