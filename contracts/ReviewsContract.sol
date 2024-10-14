pragma solidity >=0.8.4;

// SPDX-License-Identifier: MIT
// Source:
// https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/StringUtils.sol
library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

library FloatString {
    function toFloatingPointString(uint integerPart, uint fractionalPart) internal pure returns (string memory) {
        return string(abi.encodePacked(uint2str(integerPart), ".", uint2str(fractionalPart)));
    }

    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

contract  DomainContainer {
    address private owner;
    address private mainContract;

    uint private domainIDIterator;
    struct Domain {
        uint ID;
        string name;
        string desc;
    }
    mapping(string => Domain) private domains; // domainName => Domain
    mapping(uint => string) private domainNameOfID; // domainID => domainName
    mapping(string => bool) private domainExists; // domainName => bool
    mapping(string => mapping(string => bool)) private domainHasItemReviews; // domainName => itemName => bool
    mapping(string => address) private domainOwner; // domainName => owner

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can use this function");
        _;
    }

    modifier onlyMainContract() {
        require(msg.sender == mainContract, "Only main contract can use this function");
        _;
    }

    constructor(address _mainContract){
        owner = msg.sender;
        mainContract = _mainContract;
    }

    function getDomainOwner(string memory domainName) public view returns (address) {
        return domainOwner[domainName];
    }

    function setDomainOwner(string memory domainName, address _owner) public onlyMainContract {
        domainOwner[domainName] = _owner;
    }

    function checkIfDomainExists(string memory domainName) public view returns (bool) {
        return domainExists[domainName];
    }

    function getDomains() public view returns (Domain[] memory) {
        Domain[] memory domainsArray = new Domain[](domainIDIterator);
        for (uint i = 0; i < domainIDIterator; i++) {
            domainsArray[i] = domains[domainNameOfID[i]];
        }
        return domainsArray;
    }

    function addDomain(string memory domainName) public onlyMainContract {
        require(!domainExists[domainName], "Domain already exists");
        Domain storage domain = domains[domainName];
        domain.ID = domainIDIterator;
        domain.name = domainName;

        domainExists[domainName] = true;
        domainNameOfID[domainIDIterator] = domainName;
        domainIDIterator++;
    }

    function setDomainDescription(string memory domainName, string memory desc) public onlyMainContract {
        if (!domainExists[domainName]) {
            revert("Domain does not exist");
        }
        if (StringUtils.strlen(desc) > 256) {
            revert("Description too long");
        }
        domains[domainName].desc = desc;
    }

    function checkIfDomainItemReviewsExist(string memory domainName, string memory itemName) public view returns (bool) {
        return domainHasItemReviews[domainName][itemName];
    }

    function setTrueDomainItemReviewExistence(string memory domainName, string memory itemName) public onlyMainContract{
        domainHasItemReviews[domainName][itemName] = true;
    }
}

contract ItemContainer {
    address private owner;
    address private mainContract;

    uint private itemIDIterator;
    struct Item {
        uint ID;
        string name;
        string[] availableOnDomainNames;
        string rating; // Average rating of item as string
        mapping(string => string) itemDomainRating; // domainName => rating
        mapping(string => string) itemDesc; // domainName => description
    }

    mapping(string => Item) private items; // itemName => Item
    mapping(uint => string) private itemNameOfID; // itemID => itemName
    mapping(string => bool) private itemExists; // itemName => bool
    mapping(string => uint) private itemReviewCount; // itemName => count of reviews
    mapping(string => uint) private itemTotalAccumulatedRating; // itemName => total accumulated rating
    mapping(string => mapping(string => uint)) private itemDomainReviewCount; // itemName => domainName => count of reviews
    mapping(string => mapping(string => uint)) private itemDomainTotalAccumulatedRating; // itemName => domainName => total accumulated rating

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can use this function");
        _;
    }

    modifier onlyMainContract() {
        require(msg.sender == mainContract, "Only main contract can use this function");
        _;
    }

    constructor(address _mainContract){
        owner = msg.sender;
        mainContract = _mainContract;
    }

    function checkIfItemExists(string memory itemName) public view returns (bool) {
        return itemExists[itemName];
    }

    struct DomainRating {
        string domainName;
        string rating;
    }

    struct ItemDomainDescription {
        string domainName;
        string desc;
    }

    struct ReturnableItem {
        uint ID;
        string name;
        string[] availableOnDomainNames;
        string rating;
        ItemDomainDescription[] domainDescriptions;
        DomainRating[] domainRatings;
    }

    function getItems() public view returns (ReturnableItem[] memory) {
        ReturnableItem[] memory itemsArray = new ReturnableItem[](itemIDIterator);
        for (uint i = 0; i < itemIDIterator; i++) {
            string memory itemName = itemNameOfID[i];
            Item storage item = items[itemName];

            uint domainCount = item.availableOnDomainNames.length;
            ItemDomainDescription[] memory domainDescriptions = new ItemDomainDescription[](domainCount);
            DomainRating[] memory domainRatings = new DomainRating[](domainCount);

            uint k = 0;
            for (uint j = 0; j < domainCount; j++) {
                string memory domainName = item.availableOnDomainNames[j];
                domainRatings[j] = DomainRating({
                    domainName: domainName,
                    rating: item.itemDomainRating[domainName]
                });
                if (bytes(item.itemDesc[domainName]).length > 0) {
                    domainDescriptions[k] = ItemDomainDescription({
                        domainName: domainName,
                        desc: item.itemDesc[domainName]
                    });
                    k++;
                }
            }

            itemsArray[i] = ReturnableItem({
                ID: item.ID,
                name: item.name,
                availableOnDomainNames: item.availableOnDomainNames,
                rating: item.rating,
                domainDescriptions: domainDescriptions,
                domainRatings: domainRatings
            });
        }
        return itemsArray;
    }

    function getItem(string memory itemName) public view returns (ReturnableItem memory) {
        require(itemExists[itemName], "Item does not exist");

        Item storage item = items[itemName];

        uint domainCount = item.availableOnDomainNames.length;
        ItemDomainDescription[] memory domainDescriptions = new ItemDomainDescription[](domainCount);
        DomainRating[] memory domainRatings = new DomainRating[](domainCount);

        uint k = 0;
        for (uint j = 0; j < domainCount; j++) {
            string memory domainName = item.availableOnDomainNames[j];
            domainRatings[j] = DomainRating({
                domainName: domainName,
                rating: item.itemDomainRating[domainName]
            });
            if (bytes(item.itemDesc[domainName]).length > 0) {
                domainDescriptions[k] = ItemDomainDescription({
                    domainName: domainName,
                    desc: item.itemDesc[domainName]
                });
                k++;
            }
        }

        return ReturnableItem({
            ID: item.ID,
            name: item.name,
            rating: item.rating,
            availableOnDomainNames: item.availableOnDomainNames,
            domainDescriptions: domainDescriptions,
            domainRatings: domainRatings
        });
    }

    function addItem(string memory itemName) public onlyMainContract {
        require(!itemExists[itemName], "Item already exists");

        Item storage item = items[itemName];
        item.ID = itemIDIterator;
        item.name = itemName;
        item.rating = "0.00";
        item.availableOnDomainNames = new string[](0);

        itemExists[itemName] = true;
        itemNameOfID[itemIDIterator] = itemName;
        itemIDIterator++;
    }

    function checkIfItemInDomain(string memory itemName, string memory domainName) public view returns (bool) {
        string[] memory availableOnDomainNames = items[itemName].availableOnDomainNames;
        for (uint i = 0; i < availableOnDomainNames.length; i++) {
            if (keccak256(bytes(availableOnDomainNames[i])) == keccak256(bytes(domainName))) {
                return true;
            }
        }
        return false;
    }

    function addItemToDomain(string memory itemName, string memory domainName) public onlyMainContract {
        items[itemName].availableOnDomainNames.push(domainName);
    }

    function addRatingForItem(string memory itemName, string memory domainName, uint rating) public onlyMainContract {
        itemDomainReviewCount[itemName][domainName]++;
        itemDomainTotalAccumulatedRating[itemName][domainName] += rating;
        uint averageRating = (itemDomainTotalAccumulatedRating[itemName][domainName] * 100) / itemDomainReviewCount[itemName][domainName];
        items[itemName].itemDomainRating[domainName] = FloatString.toFloatingPointString(averageRating / 100, averageRating % 100);

        itemReviewCount[itemName]++;
        itemTotalAccumulatedRating[itemName] += rating;
        averageRating = (itemTotalAccumulatedRating[itemName] * 100) / itemReviewCount[itemName];
        items[itemName].rating = FloatString.toFloatingPointString(averageRating / 100, averageRating % 100);
    }

    function setItemDescription(string memory itemName, string memory domainName, string memory desc) public onlyMainContract {
        if (!itemExists[itemName]) {
            revert("Item does not exist");
        }
        if (StringUtils.strlen(desc) > 256) {
            revert("Description too long");
        }
        items[itemName].itemDesc[domainName] = desc;
    }
}

contract ReviewContainer {
    address private owner;
    address private mainContract;

    uint private reviewIDIterator;
    struct Review {
        uint ID;
        address reviewer;
        string itemName;
        string domainName;
        string comment;
        uint8 rating;
    }

    mapping(uint => Review) private reviewOfIDs; // reviewID => Review

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can use this function");
        _;
    }

    modifier onlyMainContract() {
        require(msg.sender == mainContract, "Only main contract can use this function");
        _;
    }

    constructor(address _mainContract){
        owner = msg.sender;
        mainContract = _mainContract;
    }

    function getReviews() public view returns (Review[] memory) {
        Review[] memory reviews = new Review[](reviewIDIterator);
        for (uint i = 0; i < reviewIDIterator; i++) {
            reviews[i] = reviewOfIDs[i];
        }
        return reviews;
    }

    function addReview(address user, string memory domainName, string memory itemName, string memory comment, uint8 rating) public onlyMainContract {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");

        Review storage review = reviewOfIDs[reviewIDIterator];

        review.ID = reviewIDIterator;
        review.reviewer = user;
        review.itemName = itemName;
        review.domainName = domainName;
        review.comment = comment;
        review.rating = rating;

        reviewIDIterator++;
    }
}

contract UserContainer {
    address private owner;
    address private mainContract;

    mapping(address => mapping(string => bool)) private userReviewedItem; // user => itemName => bool
    mapping(address => mapping(string => mapping(string => bool))) private userReviewedItemOnDomain; // user => itemName => domainName => bool

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can use this function");
        _;
    }

    modifier onlyMainContract() {
        require(msg.sender == mainContract, "Only main contract can use this function");
        _;
    }

    constructor(address _mainContract){
        owner = msg.sender;
        mainContract = _mainContract;
    }

    function checkIfUserReviewedItem(address user, string memory itemName) public view returns (bool) {
        return userReviewedItem[user][itemName];
    }

    function setTrueUserReviewedItem(address user, string memory itemName) public onlyMainContract {
        userReviewedItem[user][itemName] = true;
    }

    function checkIfUserReviewedItemOnDomain(address user, string memory itemName, string memory domainName) public view returns (bool) {
        return userReviewedItemOnDomain[user][itemName][domainName];
    }

    function setTrueUserReviewedItemOnDomain(address user, string memory itemName, string memory domainName) public onlyMainContract {
        userReviewedItemOnDomain[user][itemName][domainName] = true;
    }
}

contract ReviewsContract {
    address private owner;
    ReviewContainer private reviewContainer;
    ItemContainer private itemContainer;
    DomainContainer private domainContainer;
    UserContainer private userContainer;

    constructor(){
        owner = msg.sender;
        reviewContainer = new ReviewContainer(address(this));
        itemContainer = new ItemContainer(address(this));
        domainContainer = new DomainContainer(address(this));
        userContainer = new UserContainer(address(this));
    }

    function getReviewContainer() external view returns (ReviewContainer) {
        return reviewContainer;
    }

    function getItemContainer() external view returns (ItemContainer) {
        return itemContainer;
    }

    function getDomainContainer() external view returns (DomainContainer) {
        return domainContainer;
    }

    function getUserContainer() external view returns (UserContainer) {
        return userContainer;
    }

    function bindAddressToDomain(string memory domainName, address _owner) external {
        if (!domainContainer.checkIfDomainExists(domainName)) {
            domainContainer.addDomain(domainName);
        }
        require(domainContainer.getDomainOwner(domainName) == address(0), "Domain already has an owner");
        domainContainer.setDomainOwner(domainName, _owner);
    }

    function setDomainDescription(string memory domainName, string memory desc) external {
        require(domainContainer.getDomainOwner(domainName) == msg.sender, "Only domain owner can set description");
        domainContainer.setDomainDescription(domainName, desc);
    }

    function setItemDescription(string memory itemName, string memory domainName, string memory desc) external {
        require(domainContainer.getDomainOwner(domainName) == msg.sender, "Only domain owner can set description");
        if (!itemContainer.checkIfItemExists(itemName)) {
            itemContainer.addItem(itemName);
        }
        itemContainer.setItemDescription(itemName, domainName, desc);
    }

    function addReview(string memory domainName, string memory itemName, string memory comment, uint8 rating) external {
        require(rating >= 1 && rating <= 5, "Rating not between 1 and 5");
        if (bytes(domainName).length == 0 || bytes(itemName).length == 0) {
            revert("Invalid input");
        }

        // Check if review exists
        if (userContainer.checkIfUserReviewedItemOnDomain(msg.sender, itemName, domainName)) {
            revert("User already reviewed this item");
        }

        // Check if domain exists
        if (!domainContainer.checkIfDomainExists(domainName)) {
            revert("Domain does not exist");
            //domainContainer.addDomain(domainName);
        }

        // Check if item exists
        if (!itemContainer.checkIfItemExists(itemName)) {
            itemContainer.addItem(itemName);
        }

        // Add review
        reviewContainer.addReview(msg.sender, domainName, itemName, comment, rating);
        itemContainer.addRatingForItem(itemName, domainName, rating);
        if (!userContainer.checkIfUserReviewedItem(msg.sender, itemName)) {
            userContainer.setTrueUserReviewedItem(msg.sender, itemName);
        }
        if (!userContainer.checkIfUserReviewedItemOnDomain(msg.sender, itemName, domainName)) {
            userContainer.setTrueUserReviewedItemOnDomain(msg.sender, itemName, domainName);
        }

        // Add item to domain if not already in domain
        if (!itemContainer.checkIfItemInDomain(itemName, domainName)) {
            itemContainer.addItemToDomain(itemName, domainName);
        }
    }
}