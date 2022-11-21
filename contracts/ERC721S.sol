// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract ERC721S is ERC721, Ownable {
    
    uint256 public timestamp;
    uint256 public totalSupply;

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
        address payable beneficiary;
        uint256 period; /// @dev いくつの設計にするのか
        uint256 price;
        uint256 entryCount;
    }

    Plan public plan;

    /// @dev Token Idで管理するほうがわかりやすそう
    mapping(uint256 => Subscription) public subscriptions;

    constructor(
        uint256 _period,
        uint256 _price
    ) ERC721("Test", "TST") {
        // _initSubscPlan(_period, _price);
        _dafaultSubscPlan();
    }
    
    function mint() public{
        _safeMint(msg.sender, totalSupply);
        _createSubsc(totalSupply);

        totalSupply++;
    }

    function _dafaultSubscPlan() internal virtual onlyOwner{
        Plan memory _plan = Plan({
            beneficiary: payable(msg.sender),
            period: 31 days,
            price: 0 ether,
            entryCount: 0
        });
        plan = _plan;
    }

    /// @dev 初期化=> Constructorのときに処理を行う
    function _initSubscPlan(uint256 _period, uint256 _price) internal virtual onlyOwner{
        Plan memory _plan = Plan({
            beneficiary: payable(msg.sender),
            period: _period,
            price: _price,
            entryCount: 0
        });
        plan = _plan;
    }

    function transferBeneficiary(address payable newBeneficiary) public virtual onlyOwner {
        require(newBeneficiary != address(0x0), "Not newBeneficiary");
        plan.beneficiary = newBeneficiary;
    }

    /// @dev プラン情報を更新する
    function setPlan(
        uint256 _period,
        uint256 _price
    ) public virtual onlyOwner {
        // require(plan.period != 0, "No Plan");
        plan.period = _period;
        plan.price = _price;
    }

    function getPlan() public view virtual returns (Plan memory) {
        require(_existsPlan(), "No Plan");
        return plan;
    }

    function _existsPlan() internal view virtual returns (bool) {
        return plan.period != 0;
    }

    function _existsSubsc(uint256 _tokenId) internal view virtual returns (bool) {
        return subscriptions[_tokenId].entry;
    }

    function isValidSubsc(uint256 _tokenId) public view virtual returns (bool) {
        return subscriptions[_tokenId].endTime >= block.timestamp;
    }

    function price() external view virtual returns (uint256) {
        return plan.price;
    }

    function period() external view virtual returns (uint256) {
        return plan.period;
    }

    function beneficiary() external view virtual returns (address) {
        return plan.beneficiary;
    }

    function entryCount() external view virtual returns (uint256) {
        return plan.entryCount;
    }

    /// @dev トークンに紐づくサブスクリプションを作成
    function _createSubsc(uint256 _tokenId) internal virtual {
        require(!_existsSubsc(_tokenId), "Already Entry");
        require(_existsPlan(), "No Plan");

        Subscription memory subscription = Subscription({
            owner: msg.sender,
            paidAddress: msg.sender,
            number: 0,
            createTime: block.timestamp,
            updateTime: 0,
            endTime: 0,
            entry: true
        });

        subscriptions[_tokenId] = subscription;
        plan.entryCount++;
    }

    /// @dev サブスクリプションの更新処理
    function updateSubsc(uint256 _tokenId) public payable virtual {
        require(_existsSubsc(_tokenId), "No Entry");
        require(
            msg.value >= plan.price,
            "Not enought ETH"
        );
        require(!isValidSubsc(_tokenId), "Already pass");
        
        console.log(plan.price);
        plan.beneficiary.transfer(msg.value);
        
        Subscription storage subsc = subscriptions[_tokenId];
        subsc.paidAddress = msg.sender;
        subsc.updateTime = block.timestamp;
        subsc.endTime = block.timestamp + plan.period;
        subsc.number++;
    }

    /// @dev サブスクリプションの更新処理
    function updateSubsInAdvance(uint256 _tokenId, uint256 num) public payable virtual {
        require(subscriptions[_tokenId].entry, "No Entry");
        require(
            msg.value >= plan.price * num,
            "Not enought ETH"
        );
        require(
            subscriptions[_tokenId].endTime <= block.timestamp,
            "Already pass"
        );
        require(plan.price != 0, "Zero"); /// @dev ゼロは何回やってもゼロPrice
        
        console.log(plan.price * num);
        plan.beneficiary.transfer(msg.value * num);
        
        Subscription storage subsc = subscriptions[_tokenId];
        subsc.paidAddress = msg.sender;
        subsc.updateTime = block.timestamp;
        subsc.endTime = block.timestamp + plan.period * num;
        subsc.number += num;
    }

    /// @dev キャンセル処理→あまり必要がない
    function cancelSubscription(uint256 tokenId) public virtual {
        Subscription storage subsc = subscriptions[tokenId];
        subsc.entry = false;
    }

    /// @dev サブスクの登録ができているかどうか
    function getEntry(uint256 tokenId) public view virtual returns (bool) {
        return subscriptions[tokenId].entry;
    }

    /// @dev サブスク有効判定
    function getJudgement(uint256 tokenId) public view virtual returns (bool) {
        console.log(block.timestamp,subscriptions[tokenId].endTime);
        return block.timestamp < subscriptions[tokenId].endTime;
    }

    // function setTimestamp() external {
    //     timestamp = block.timestamp;
    //     console.log(timestamp);
    // }

    function getNow() external view virtual returns (uint256){
        return block.timestamp;
    }

    function getExpDate(uint256 _tokenId) external view virtual returns (uint256){
        return (subscriptions[_tokenId].endTime - block.timestamp) / 1 days;
    }

    // function getBool() external view returns (bool) {
    //     return timestamp + 30 seconds > block.timestamp;
    // }
}