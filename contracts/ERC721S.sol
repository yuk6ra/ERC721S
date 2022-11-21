// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "./SubscManager.sol";
import "hardhat/console.sol";

contract ERC721S is ERC721, Ownable {
    
    uint256 public timestamp;
    uint256 public totalSupply;
    address payable receiveAddr;

    struct Subscription {
        address owner; /// @dev NFTを持っているオーナーのアドレス
        address paidAddress; /// @dev 別の垢で支払った垢が
        uint256 number; /// @dev 課金回数
        uint256 createTime;
        uint256 updateTime;
        uint256 endTime;
        bool entry; /// @dev アカウントの登録状態
    }

    struct Plan {
        uint256 period; /// @dev いくつの設計にするのか
        uint256 price;
        uint256 entryCount;
    }

    Plan public subscPlan;

    /// @dev Token Idで管理するほうがわかりやすそう
    mapping(uint256 => Subscription) public subscriptions;

    constructor(
        uint256 _period,
        uint256 _price
    ) ERC721("Test", "TST") {
        initSubscriptionPlan(_period, _price);
    }
    
    function mint() external {
        _safeMint(msg.sender, totalSupply);
        _createSubscription(totalSupply);

        totalSupply++;
    }

    /// @dev 初期化=> Constructorのときに処理を行う
    function initSubscriptionPlan(uint256 _period, uint256 _price) public onlyOwner{
        receiveAddr = payable(msg.sender);
        console.log(receiveAddr);
        Plan memory plan = Plan({
            period: _period,
            price: _price,
            entryCount: 0
        });
        subscPlan = plan;
    }

    /// @dev 情報を更新する
    function setPlan(
        uint256 _period,
        uint256 _price
    ) public onlyOwner {
        // require(plan.period != 0, "No Plan");
        subscPlan.period = _period;
        subscPlan.price = _price;
    }

    function getPlan() public view returns (Plan memory) {
        require(subscPlan.period != 0, "No Plan");
        return subscPlan;
    }

    /// @dev トークンに紐づくサブスクリプションを作成
    function _createSubscription(uint256 _tokenId) internal  {
        require(!subscriptions[_tokenId].entry, "Already Entry");        
        require(subscPlan.period != 0, "No Plan");
        
        require(msg.value >= subscPlan.price, "Not enought ETH");
        // require(, "Not enought ETH");
        // require(msg.value >= subscPlan.price, "Not ")
        receiveAddr.transfer(msg.value);

        Subscription memory subscription = Subscription({
            owner: msg.sender,
            paidAddress: msg.sender,
            number: 1,
            createTime: block.timestamp,
            updateTime: block.timestamp,
            endTime: block.timestamp + subscPlan.period,
            entry: true
        });

        subscriptions[_tokenId] = subscription;
        subscPlan.entryCount++;
    }

    /// @dev サブスクリプションの更新処理
    function updateSubscription(uint256 _tokenId) public payable {
        require(subscriptions[_tokenId].entry, "No Entry");
        require(
            msg.value >= subscPlan.price,
            "Not enought ETH"
        );
        
        Subscription storage subsc = subscriptions[_tokenId];
        subsc.updateTime = block.timestamp;
        subsc.endTime = block.timestamp + subscPlan.period;
        subsc.paidAddress = msg.sender;

        subsc.number++;
    }

    /// @dev キャンセル処理→あまり必要がない
    function cancelSubscription(uint256 tokenId) public {
        Subscription storage subsc = subscriptions[tokenId];
        subsc.entry = false;
    }

    /// @dev サブスクの登録ができているかどうか
    function getEntry(uint256 tokenId) public view returns (bool) {
        return subscriptions[tokenId].entry;
    }

    /// @dev サブスク有効判定
    function getJudgement(uint256 tokenId) public view returns (bool) {
        console.log(block.timestamp,subscriptions[tokenId].endTime);
        return block.timestamp < subscriptions[tokenId].endTime;
    }

    // function setTimestamp() external {
    //     timestamp = block.timestamp;
    //     console.log(timestamp);
    // }

    function getNow() external view returns (uint256){
        return block.timestamp;
    }

    // function getBool() external view returns (bool) {
    //     return timestamp + 30 seconds > block.timestamp;
    // }
}