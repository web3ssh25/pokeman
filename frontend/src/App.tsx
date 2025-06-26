import React, { useState, useEffect } from 'react';
import { BrowserProvider, Contract } from "ethers";
import NFTGallery from './NFTGallery';
import OwnerDashboard from './OwnerDashboard';
import UserDashboard from './UserDashboard';
import PokemanNFTAbi from './abi/PokemanNFT.json';
import './App.css';

const POKEMAN_NFT_ADDRESS = process.env.REACT_APP_POKEMANNFT_ADDRESS;

function App() {
  const [address, setAddress] = useState<string | null>(null);
  const [provider, setProvider] = useState<BrowserProvider | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);
  const [isOwner, setIsOwner] = useState(false);

  useEffect(() => {
    if ((window as any).ethereum) {
      const handleAccountsChanged = (accounts: string[]) => {
        if (accounts.length > 0) {
          setAddress(accounts[0]);
          setProvider(new BrowserProvider((window as any).ethereum));
        } else {
          setAddress(null);
          setProvider(null);
          setIsOwner(false);
        }
        handleRefresh();
      };

      (window as any).ethereum.on('accountsChanged', handleAccountsChanged);

      return () => {
        (window as any).ethereum.removeListener('accountsChanged', handleAccountsChanged);
      };
    }
  }, []);

  useEffect(() => {
    const checkOwnership = async () => {
      if (!provider || !address || !POKEMAN_NFT_ADDRESS) {
        setIsOwner(false);
        return;
      }
      try {
        const nftContract = new Contract(POKEMAN_NFT_ADDRESS, PokemanNFTAbi.abi, provider);
        const ownerAddress = await nftContract.owner();
        setIsOwner(ownerAddress.toLowerCase() === address.toLowerCase());
      } catch (error) {
        console.error("Failed to check ownership:", error);
        setIsOwner(false);
      }
    };
    checkOwnership();
  }, [provider, address]);

  const handleRefresh = () => {
    setRefreshKey(prevKey => prevKey + 1);
  };

  // Connect wallet
  const connectWallet = async () => {
    if ((window as any).ethereum) {
      try {
        const ethProvider = new BrowserProvider((window as any).ethereum);
        const accounts = await ethProvider.send("eth_requestAccounts", []);
        const userAddress = accounts[0];
        setAddress(userAddress);
        setProvider(ethProvider);
      } catch (err) {
        alert('Wallet connection failed');
      }
    } else {
      alert('MetaMask not detected');
    }
  };

  // Disconnect wallet (just clears state)
  const disconnectWallet = () => {
    setAddress(null);
    setProvider(null);
  };

  return (
    <div className="app-container">
      <div className="app-header">
        <h1>Pokéman NFT Marketplace</h1>
        {!address ? (
          <button className="wallet-button" onClick={connectWallet}>
            Connect Wallet
          </button>
        ) : (
          <div className="wallet-info">
            <p className="connected-address">Connected: {address}</p>
            <button className="wallet-button" onClick={disconnectWallet}>
              Disconnect
            </button>
          </div>
        )}
      </div>

      {provider && address && (
        <>
          {isOwner ? (
            <OwnerDashboard 
              provider={provider} 
              userAddress={address} 
              handleRefresh={handleRefresh} 
            />
          ) : (
            <UserDashboard
              provider={provider}
              userAddress={address}
              refreshKey={refreshKey}
              handleRefresh={handleRefresh}
            />
          )}
          <NFTGallery 
            provider={provider} 
            userAddress={address}
            refreshKey={refreshKey}
            handleRefresh={handleRefresh}
          />
        </>
      )}
    </div>
  );
}

export default App;