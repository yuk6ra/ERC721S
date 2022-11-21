// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "./SubscManager.sol";
import "hardhat/console.sol";

contract ERC721S is ERC721, Ownable {
    
    uint256 public timestamp;
    uint256 public totalSupply;
    uint256 public planCount; /// @dev option: 数字

    struct Subscription {
        address owner; /// @dev NFTを持っているオーナーのアドレス
        address paidAddress; /// @dev 別の垢で支払った垢が
        uint256 number; /// @dev 課金回数
        uint256 createTime;
        uint256 updateTime;
        uint256 endTime;
        uint256 planNumber; /// @dev オプション
        bool entry; /// @dev アカウントの登録状態
    }

    struct Plan {
        uint256 period; /// @dev いくつの設計にするのか
        uint256 price;
        uint256 entryCount;
    }

    /// @dev Token Idで管理するほうがわかりやすそう
    mapping(uint256 => Subscription) public subscriptions;
    mapping(uint256 => Plan) public plans;

    constructor(
        uint256 _period,
        uint256 _price
    ) ERC721("Test", "TST") {
        initSubscriptionPlan(_period, _price);
    }
    
    function mint(uint256 _planNumber) external payable {
        _safeMint(msg.sender, totalSupply);

        createSubscription(totalSupply, _planNumber);

        totalSupply++;
    }


    /// @dev 初期化=> Constructorのときに処理を行う
    function initSubscriptionPlan(uint256 _period, uint256 _price) public onlyOwner{
        Plan memory plan = Plan({
            period: _period,
            price: _price,
            entryCount: 0
        });
        
        plans[planCount] = plan;
        planCount++;
    }

    // @dev プランを追加する
    function addPlan(
        uint256 _period,
        uint256 _price
    ) public onlyOwner {
        Plan memory plan = Plan({
            period: _period,
            price: _price,
            entryCount: 0
        });

        plans[planCount] = plan;

        planCount++; /// @dev プランの数を返す
    }

    /// @dev 情報を更新する
    function setPlan(
        uint256 _planCount,
        uint256 _period,
        uint256 _price
    ) public onlyOwner {
        require(plans[_planCount].period != 0, "No Plan");

        Plan storage plan = plans[_planCount];
        plan.period = _period;
        plan.price = _price;
    }

    function deletePlan(uint256 _planNumber) public onlyOwner {
        require(plans[_planNumber].period != 0, "No Plan");
        delete plans[_planNumber];
        planCount--;
    }

    function getPlan(uint256 _planCount) public view returns (Plan memory) {
        require(plans[_planCount].period != 0, "No Plan");
        return plans[_planCount];
    }

    /// @dev トークンに紐づくサブスクリプションを作成
    function createSubscription(uint256 _tokenId, uint256 _planNumber) public payable  {
        require(!subscriptions[_tokenId].entry, "Already Entry");        
        require(plans[_planNumber].period != 0, "No Plan");
        
        require(msg.value >= plans[_planNumber].price, "Not enought ETH");

        Subscription memory subscription = Subscription({
            owner: msg.sender,
            paidAddress: msg.sender,
            number: 1,
            createTime: block.timestamp,
            updateTime: block.timestamp,
            endTime: block.timestamp + plans[_planNumber].period,
            planNumber: _planNumber,
            entry: true
        });

        subscriptions[_tokenId] = subscription;
        plans[_planNumber].entryCount++;
    }

    /// @dev サブスクリプションの更新処理
    function updateSubscription(uint256 _tokenId) public payable {
        require(subscriptions[_tokenId].entry, "No Entry");
        require(
            msg.value >= plans[subscriptions[_tokenId].planNumber].price,
            "Not enought ETH"
        );
        
        Subscription storage subsc = subscriptions[_tokenId];
        subsc.updateTime = block.timestamp;
        subsc.endTime = block.timestamp + plans[subsc.planNumber].period;
        subsc.paidAddress = msg.sender;

        subsc.number++;
    }

    /// @dev 更新のオプション処理
    function updatePlan(uint256 _tokenId, uint256 _planNumber) public {        
        require(subscriptions[_tokenId].entry, "No Entry");
        require(plans[_planNumber].period != 0, "No Plan");

        Subscription storage subsc = subscriptions[_tokenId];        
        subsc.planNumber = _planNumber;

        updateSubscription(_tokenId); /// @dev サブスクリプションの処理も行う
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