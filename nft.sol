// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.9.0;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/common/ERC2981.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';

contract NFT is ERC721, ERC721Enumerable, ERC2981, Ownable {
    uint public minted = 0;    //count of nfts minted by the owner
    uint public total_supply;  //total amount of nfts present - includes non minted nfts
    uint public sold = 0;       //nfts sold
    string public contractURI;         
    uint royaltyFee;            //royalty fee multiplied by 100 so 2.5% is 250
    mapping(address => uint) nfts; //stores the token number with it's owner address
    address receiver;              //person to which royalty goes to and deployer of contract
    uint public ether_price = 0.01 ether;
    string private TokenURI = "https://gateway.pinata.cloud/ipfs/QmWmkFRK4qfA69iq8oeUbdzeoa3essYH4GobAXwHN26zqS";

    constructor(uint96 _royaltyFeesInHundreds, string memory _contractURI, uint _total_supply) ERC721("Boxes", "BOX") {
        receiver = msg.sender; //set developer
        total_supply = _total_supply;
        setRoyaltyInfo(msg.sender, _royaltyFeesInHundreds);
        contractURI = _contractURI;
        royaltyFee = _royaltyFeesInHundreds;
    }

    //increase total supply
    function incTotalSupply(uint _amount) public onlyOwner{
        total_supply += _amount;
    }

    event Received(address, uint);

    //owner mints some amoount of nfts
    function mint (uint amount) public onlyOwner{
        require(minted+amount <= total_supply, "tokens exceed limit");
        uint _tokenId = minted; //so next minted nft's ID starts right after the previous one
        while (minted < total_supply && amount!=0) {
            _tokenId += 1;  //to give them an ID
            minted += 1;
            _safeMint(msg.sender, _tokenId);
            amount--;
        }
    }     //while minted nfts stay less than non-minted+minted amount
   

    //user buys the nfts that owner has already minted
    //users cannot buy more than nft on primary sale
    function buy() public payable{
        require(minted >= sold, "sold out!"); 
        require(minted <= total_supply, "out of stock");
        require(nfts[msg.sender] < 1, "cannot buy more than one nft");
        require(msg.value == ether_price, "Wrong amount of ether");
        emit Received(msg.sender, msg.value);
        payable(receiver).transfer(ether_price / 100); //send "royalty" to developer on primary sale
        sold += 1;
        nfts[msg.sender] = sold; //sets which address owns which nft
        _transfer(receiver, msg.sender, sold);
    }    

    function setPrice(uint _newPrice) public onlyOwner{
        require(_newPrice > 0, "price has to be non-negative and non zero");
        ether_price = _newPrice;
    }

    function setOwner(address _newOwner) public onlyOwner{
        receiver = _newOwner;
    }

    function setContractURI(string memory _newContractURI) public onlyOwner{
        contractURI = _newContractURI;
    }

    function setTokenURI(string memory _newTokenURI) public onlyOwner{
        TokenURI = _newTokenURI;
    }

    //tells which address owns which nft
    function ownes(address _address) public view returns(uint) {
        return nfts[_address];
    }

    function seeEtherBalance (address _address) public view returns (uint) {
        return _address.balance;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner{
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    //so owner can withdraw ether from contract
    function withdrawAllEther() public onlyOwner{
        payable(receiver).transfer(address(this).balance);
    }

    function tokenURI(uint _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(TokenURI, "/", Strings.toString(_tokenId), ".json"));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view virtual returns (address, uint256) {
    //     return (developer, calculateRoyalty(_salePrice));
    // }

    function royaltyInfo(uint256 _salePrice) external view virtual returns (address, uint256) {
        return (receiver, calculateRoyaltyInWei(_salePrice));
    }

    function calculateRoyaltyInWei(uint256 _salePrice) view public returns (uint256) {
        return (_salePrice * 10 ** 18 / 10000) * royaltyFee ; //returns in wei
    }
}
//https://www.npoint.io/docs/27f8ee01e168cb99bcc9
