import React, { useState, useEffect } from 'react';
import { BrowserProvider, Contract } from 'ethers';
import PokeTokenAbi from './abi/PokeToken.json';
import PokemanNFTAbi from './abi/PokemanNFT.json';
import PokemanMarketplaceAbi from './abi/PokemanMarketplace.json';
import './OwnerDashboard.css';

interface Props {
  provider: BrowserProvider | null;
  userAddress: string | null;
  handleRefresh: () => void;
}

interface UserBalance {
  address: string;
  balance: string;
}

const OwnerDashboard: React.FC<Props> = ({ provider, userAddress, handleRefresh }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [airdropAddress, setAirdropAddress] = useState('');
  const [airdropAmount, setAirdropAmount] = useState('');
  const [userBalances, setUserBalances] = useState<UserBalance[]>([]);
  const [mintNftId, setMintNftId] = useState('');
  const [listForMintingNftIds, setListForMintingNftIds] = useState('');
  const [listNftId, setListNftId] = useState('');
  const [listingPrice, setListingPrice] = useState('');
  const [status, setStatus] = useState('');

  const POKE_TOKEN_ADDRESS = process.env.REACT_APP_POKETOKEN_ADDRESS!;
  const POKEMAN_NFT_ADDRESS = process.env.REACT_APP_POKEMANNFT_ADDRESS!;

  useEffect(() => {
    fetchUserBalances();
  }, [provider, userAddress]);

  const fetchUserBalances = async () => {
    if (!provider) return;
    try {
      const signer = await provider.getSigner();
      const tokenContract = new Contract(POKE_TOKEN_ADDRESS, PokeTokenAbi.abi, signer);
      // For demo purposes, we'll just show the last few transactions to get addresses
      const filter = tokenContract.filters.Transfer();
      const events = await tokenContract.queryFilter(filter);
      const uniqueAddresses = new Set<string>();
      events.forEach(event => {
        if ('args' in event) {
          uniqueAddresses.add(event.args[0]);
          uniqueAddresses.add(event.args[1]);
        }
      });

      const balances = await Promise.all(
        Array.from(uniqueAddresses).map(async (address) => {
          const balance = await tokenContract.balanceOf(address);
          return {
            address,
            balance: balance.toString()
          };
        })
      );
      setUserBalances(balances);
    } catch (err) {
      console.error('Error fetching balances:', err);
    }
  };

  const handleAirdrop = async () => {
    if (!provider || !airdropAddress || !airdropAmount) return;
    try {
      setStatus('Initiating airdrop...');
      const signer = await provider.getSigner();
      const tokenContract = new Contract(POKE_TOKEN_ADDRESS, PokeTokenAbi.abi, signer);
      const tx = await tokenContract.transfer(airdropAddress, airdropAmount);
      await tx.wait();
      setStatus('Airdrop successful!');
      fetchUserBalances();
      handleRefresh();
      setAirdropAddress('');
      setAirdropAmount('');
    } catch (err: any) {
      setStatus('Airdrop failed: ' + err.message);
    }
  };

  const handlePreMintNFT = async () => {
    if (!provider || !mintNftId) return;
    try {
      setStatus('Minting NFT...');
      const signer = await provider.getSigner();
      const nftContract = new Contract(POKEMAN_NFT_ADDRESS, PokemanNFTAbi.abi, signer);
      const tx = await nftContract.preMint([mintNftId]);
      await tx.wait();
      setStatus('NFT minted successfully!');
      handleRefresh();
      setMintNftId('');
    } catch (err: any) {
      setStatus('Minting failed: ' + err.message);
    }
  };

  const handleListNFTsForMinting = async () => {
    if (!provider || !listForMintingNftIds) return;
    try {
      setStatus('Listing NFTs for minting...');
      const signer = await provider.getSigner();
      const nftContract = new Contract(POKEMAN_NFT_ADDRESS, PokemanNFTAbi.abi, signer);
      const ids = listForMintingNftIds.split(',').map(id => id.trim());
      const tx = await nftContract.setAvailableForMint(ids);
      await tx.wait();
      setStatus('NFTs listed for minting successfully!');
      handleRefresh();
      setListForMintingNftIds('');
    } catch (err: any) {
      setStatus('Listing for minting failed: ' + err.message);
    }
  };

  const handleListNFTforSelling = async () => {
    if (!provider || !listNftId || !listingPrice) return;
    try {
      setStatus('Approving marketplace...');
      const signer = await provider.getSigner();
      
      const nftContract = new Contract(POKEMAN_NFT_ADDRESS!, PokemanNFTAbi.abi, signer);
      const marketAddress = process.env.REACT_APP_MARKETPLACE_ADDRESS!;
      console.log(marketAddress + " " + listNftId)
      const approveTx = await nftContract.approveFromContract(marketAddress, listNftId);
      await approveTx.wait();

      setStatus('Listing NFT...');
      const marketContract = new Contract(marketAddress, PokemanMarketplaceAbi.abi, signer);
      const tx = await marketContract.list(listNftId, listingPrice);
      await tx.wait();

      setStatus('NFT listed successfully!');
      handleRefresh();
      setListNftId('');
      setListingPrice('');
    } catch (err: any) {
      setStatus('Listing failed: ' + err.message);
    }
  };

  return (
    <div className="owner-dashboard">
      <button onClick={() => setIsOpen(!isOpen)} className="toggle-dashboard-button">
        {isOpen ? 'Hide' : 'Show'} Owner Dashboard
      </button>
      {isOpen && (
        <div className="dashboard-content">
          <h2>Owner Dashboard</h2>
          
          <div className="dashboard-section">
            <h3>Airdrop PokeTokens</h3>
            <div className="input-group">
              <input
                type="text"
                placeholder="Address"
                value={airdropAddress}
                onChange={(e) => setAirdropAddress(e.target.value)}
              />
              <input
                type="number"
                placeholder="Amount"
                value={airdropAmount}
                onChange={(e) => setAirdropAmount(e.target.value)}
              />
              <button onClick={handleAirdrop}>Airdrop</button>
            </div>
          </div>

          <div className="dashboard-section">
            <h3>User Balances</h3>
            <div className="balances-list">
              {userBalances.map((balance) => (
                <div key={balance.address} className="balance-item">
                  <span className="address">{balance.address}</span>
                  <span className="balance">{balance.balance} POKE</span>
                </div>
              ))}
            </div>
          </div>

          <div className="dashboard-section">
            <h3>Pre Mint NFT</h3>
            <div className="input-group">
              <input
                type="number"
                placeholder="NFT ID"
                value={mintNftId}
                onChange={(e) => setMintNftId(e.target.value)}
              />
              <button onClick={handlePreMintNFT}>PreMint</button>
            </div>
          </div>

          <div className="dashboard-section">
            <h3>List NFTs for Minting</h3>
            <div className="input-group">
              <input
                type="text"
                placeholder="NFT IDs (comma-separated)"
                value={listForMintingNftIds}
                onChange={(e) => setListForMintingNftIds(e.target.value)}
              />
              <button onClick={handleListNFTsForMinting}>List for Minting</button>
            </div>
          </div>

          <div className="dashboard-section">
            <h3>List NFT for Sell</h3>
            <div className="input-group">
              <input
                type="number"
                placeholder="NFT ID"
                value={listNftId}
                onChange={(e) => setListNftId(e.target.value)}
              />
              <input
                type="number"
                placeholder="Price"
                value={listingPrice}
                onChange={(e) => setListingPrice(e.target.value)}
              />
              <button onClick={handleListNFTforSelling}>List</button>
            </div>
          </div>

          {status && <div className="status-message">{status}</div>}
        </div>
      )}
    </div>
  );
};

export default OwnerDashboard; 