// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

contract CryptoCareFactory {
    address constant superAdmin = 0xf872Dc10b653f2c5f40aCb9Bc38E725EFafeD092;

    mapping(address => bool) public admin;
    mapping(address => bool) public verifiedAddress;
    mapping(address => string) public userName;
    mapping(address => string) public photoUrl;

    uint public campaignCount;
    Campaign[] public deployedCampaign;

    function getAddress(address _user) public view returns (bool, string memory) {
        return (verifiedAddress[_user], userName[_user]);
    }

    // ACCESS MODIFIER ====
    modifier onlyVerified() {
        require(verifiedAddress[msg.sender] == true, "Your address not verified!");
        _;
    }
    modifier onlySuperAdmin() {
        require(superAdmin == msg.sender);
        _;
    }
    modifier onlyAdmin() {
        require(admin[msg.sender] == true);
        _;
    }
    
    // FUNCTION SET n UNSET ADMIN (SUPER ADMIN)
    function setToAdmin(address _user) public onlySuperAdmin{
        admin[_user] = true;
    }

    function deleteAdmin(address _user) public onlySuperAdmin{
        admin[_user] = false;
    }

    // FUNCTION VERIF n UNVERIF USER (ADMIN)
    function setAddressVerified(address _user) public onlyAdmin {
        verifiedAddress[_user] = true;
        userName[_user] = "User";
    }    

    function setAddressUnverified(address _user) public onlyAdmin {
        verifiedAddress[_user] = false;
        userName[_user] = "User";
    }

    // Function Set UserName
    function setUsername(address _user, string memory _name) public onlyVerified {
        userName[_user] = _name;
    } 
    
    // Function Set UserName
    function setPhoto(address _user, string memory _url) public onlyVerified {
        photoUrl[_user] = _url;
    } 

    function getCampaigns() public view returns (Campaign[] memory){
        return deployedCampaign;
    }

    //CREATE NEW Regular CAMPAIGN
    function createCampaigns(string memory _title, string memory _url, string memory _story, uint _duration, uint _target, uint _tipes, string memory _category, uint _minimum) external 
    {
        campaignCount += 1;
        uint _id = campaignCount;
        // Normal = 0
        // Urgent = 1
        uint typeCampaign;
        if (!verifiedAddress[msg.sender]){
            typeCampaign = 0;
        }
        else {
            typeCampaign = _tipes;
        }
        Campaign newCampaigns = new Campaign(_id, _title, _url, _story, block.timestamp, _duration, msg.sender,_target, typeCampaign, _category, _minimum);
        deployedCampaign.push(newCampaigns); 

    }
}

contract Campaign {
    mapping(address => bool) public donors;
    mapping(address => bool) public voter; // apakah address diberi izin untuk vote (jika melebihi minimal donasi akan diberikan hak untuk vote)
    mapping(address => bool) public reported; // apakah user sudah pernah melakukan report
    mapping(address => uint) public donatedValue; // Menyimpan besaran donasi dari setiap alamat
    
    uint public voterCount; // Total dari user yang diberikan izin vote
    uint public donatursCount; // Total dari jumlah seluruh donasi
    uint public campaignReport; // Jumlah report
    uint public collectedFunds; // Jumlah dana yang sudah terkumpul
    bool campaignActive; // Cek apakah campaign masih aktif

    // Menyimpan riwayat dari setiap donasi (Address dana jumlah donasinya)
    address[] public contributors; 
    uint[] public donations;

    uint campaignId;
    string campaignTitle; //*
    string campaignUrl; //*
    string[] campaignStory; //*
    uint campaignTimestamp;
    uint campaignDuration; //*
    address campaignCreator;
    uint campaignTarget; //*
    uint  campaignTypes; //*
    string campaignCategory; //*
    uint minimContribution; // Minimal kontribusi agar bisa mendapatkan hak untuk voting

    function getDetailed() public view returns(uint, uint, address[] memory, uint[] memory, uint, uint){
        return(voterCount, campaignReport,contributors, donations,minimContribution, voterCount);
    }

    function getCampaign() public view returns(string memory, string memory, string[] memory, uint, uint, address, uint, string memory, uint, uint, uint,bool ){
        return (campaignTitle, campaignUrl, campaignStory, campaignTimestamp, collectedFunds, campaignCreator, campaignTypes, campaignCategory, campaignTarget, donatursCount,campaignDuration,campaignActive);
    }

    constructor(uint _id, string memory _title, string memory _url, string memory _story, uint _date, uint _duration, address _creator, uint _target, uint _tipes, string memory _category, uint _minimum) {
        campaignId = _id;
        campaignTitle = _title;
        campaignUrl = _url;
        campaignStory.push(_story);
        campaignTimestamp = _date;
        campaignDuration = _duration;
        campaignCreator = _creator;
        campaignTarget = _target;
        campaignTypes = _tipes;
        campaignCategory = _category;
        minimContribution = _minimum;

        donatursCount = 0;
        collectedFunds = 0;
        campaignActive = true;
    }
    
    function editCampaign(string memory _title, string memory _url, uint _minimum) public {
        campaignTitle = _title;
        campaignUrl = _url;
        minimContribution = _minimum;
    }

    function endCampaign() public {
        campaignActive = false;
    }

    //Access Modifier ====
    modifier onlyOwner() {
        require(msg.sender == campaignCreator);
        _;
    }

    modifier onlyVoter() {
        require(voter[msg.sender]);
        _;
    }

    modifier onlyActive() {
        require(campaignActive == true);
        _;        
    }

    // DONATE FUNCTION ====
    function contribute() public payable onlyActive{
        uint256 amount = msg.value;

        contributors.push(msg.sender);
        donations.push(amount);

        collectedFunds = collectedFunds + amount;
        donatedValue[msg.sender] = donatedValue[msg.sender]+ msg.value;
        donors[msg.sender]=true;
        donatursCount++;
        
        if(donatedValue[msg.sender] >= minimContribution && !voter[msg.sender]){
            voter[msg.sender] = true;
            voterCount++;
        }        
    } 
    
    // Withdrawl Request Struct ===
    struct WithdrawlStruct {
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint createTimestamp;
        uint completedTimestamp;
        uint approvalsCount;
    }

    mapping(address => mapping(uint=>bool)) public approvals;

    WithdrawlStruct[] public withdrawls;

    function getRequestWithdrawl() public view returns(WithdrawlStruct[] memory){
        return withdrawls;
    }

    // Create Withdrawl Request
    function createWithdrawl(string memory _description, uint _value, address payable _recipient) public onlyOwner{      
        require(_value <= address(this).balance, "The desired funds are not sufficient to make a withdrawal");

        WithdrawlStruct storage r = withdrawls.push();
            r.description = _description;
            r.value = _value;
            r.recipient = _recipient;
            r.complete = false;
            r.createTimestamp = block.timestamp;
            r.approvalsCount = 0;
    }

    // Approve Withdrawl Request
    function approvalWithdrawl(uint index) public onlyVoter onlyActive{
        WithdrawlStruct storage w = withdrawls[index];

        require(voter[msg.sender], "Address can't vote");
        require(!approvals[msg.sender][index], "User already voted!"); // User has not voted

        approvals[msg.sender][index] = true;
        w.approvalsCount++;
    }

    function cancelApprovalWithdrawl(uint index) public onlyVoter onlyActive{
        WithdrawlStruct storage w = withdrawls[index];

        require(voter[msg.sender], "Address can't vote");
        require(approvals[msg.sender][index], "User not vote yet"); // User has not voted

        approvals[msg.sender][index] = false;
        w.approvalsCount--;
    }

    // Finalize Withdrawl
    // UseEffect
    function finalizeWd(uint index) public onlyOwner onlyActive{
        WithdrawlStruct storage wd = withdrawls[index];

        require(wd.approvalsCount >= (voterCount / 2), "Approval has not exceeded 50%");
        require(!wd.complete, "This withdrawal has been completed");

        (bool sent, ) = payable(wd.recipient).call{value: wd.value}("");

        if(sent){
            wd.complete = true;
            wd.completedTimestamp = block.timestamp;
        }
    }

    function urgentWd(string memory description, address payable recipient, uint wdValue) public onlyOwner onlyActive{

        WithdrawlStruct storage wd = withdrawls.push();
        require(campaignTypes == 1, "This type of campaign is not urgent");
        require(!wd.complete, "This withdrawal has been completed");
        require(wdValue <= address(this).balance, "Not enough amount");

        (bool sent, ) = payable(recipient).call{value: wdValue}("");

        if(sent){
            wd.description = description;
            wd.value = wdValue;
            wd.recipient = recipient;
            wd.completedTimestamp = block.timestamp;
            wd.approvalsCount = 0;
            wd.complete = true;
        }      
    }

    function reportCampaign () public {
        require(reported[msg.sender] == false,"already vote");
         require(donors[msg.sender]);
         
        campaignReport++;
        reported[msg.sender] = true;
        if (campaignReport > (donatursCount/2) && donatursCount >= 3){
            campaignActive = false;
        }
    }

    function refundDonate() public {
        address  _to = msg.sender;

        require(donors[_to]);
        require(donatedValue[_to] > 0);
        uint256 amount = donatedValue[_to];

        (bool sent, ) = payable(_to).call{value: amount}("");
 
        if(sent){
            collectedFunds = collectedFunds - amount;
            donatedValue[_to] = 0;
            donors[_to] = false;
            donatursCount--;
            if(voter[_to]){
                voterCount--;
                voter[_to] = false;
            }
        }
    } 
}