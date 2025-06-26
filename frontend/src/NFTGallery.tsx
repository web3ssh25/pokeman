import React, { useEffect, useState } from 'react';
import { BrowserProvider, Contract } from 'ethers';
import PokemanNFTAbi from './abi/PokemanNFT.json';
import PokemanMarketplaceAbi from './abi/PokemanMarketplace.json';
import PokeTokenAbi from './abi/PokeToken.json';
import './NFTGallery.css';

const POKEMAN_NFT_ADDRESS = process.env.REACT_APP_POKEMANNFT_ADDRESS;
const POKEMAN_MARKETPLACE_ADDRESS = process.env.REACT_APP_MARKETPLACE_ADDRESS;

interface NFTGalleryProps {
  provider: BrowserProvider | null;
  userAddress: string | null;
  refreshKey: number;
  handleRefresh: () => void;
}

interface NFTInfo {
  tokenId: string;
  owner: string | null;
  price: string;
  seller: string;
  name: string;
  image: string;
}

function truncateAddress(addr: string) {
  return addr.slice(0, 6) + '...' + addr.slice(-4);
}

const NFTGallery: React.FC<NFTGalleryProps> = ({ provider, userAddress, refreshKey, handleRefresh }) => {
  const [nfts, setNfts] = useState<NFTInfo[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [txStatus, setTxStatus] = useState<{ id: string; msg: string } | null>(null);

  // Simple in-memory cache for metadata
  const metadataCache: Record<string, { name: string; image: string }> = {};

  const fetchNFTs = async () => {
    if (!provider || !POKEMAN_NFT_ADDRESS || !POKEMAN_MARKETPLACE_ADDRESS) return;
    setLoading(true);
    setError(null);
    try {
      const nft = new Contract(POKEMAN_NFT_ADDRESS!, PokemanNFTAbi.abi, provider);
      const market = new Contract(POKEMAN_MARKETPLACE_ADDRESS!, PokemanMarketplaceAbi.abi, provider);
      
      // Get all valid IDs
      const ids: string[] = (await nft.getAllValidIDs()).map((id: any) => id.toString());
      console.log(ids)
      const results = await Promise.all(
        ids.map(async (id) => {
          // On-chain info
          let owner: string | null = null;
          try {
            owner = await nft.ownerOf(id);
          } catch (err) {
            owner = null; // Not minted yet
          }
          const listing = await market.listings(id);
          let price = "";
          let seller = "";
          if (listing && listing.price && listing.price.toString() !== "0") {
            price = listing.price.toString();
            seller = listing.seller;
          }
          // PokéAPI metadata
          let name = "";
          let image = "";
          if (metadataCache[id]) {
            name = metadataCache[id].name;
            image = metadataCache[id].image;
          } else {
            try {
              const resp = await fetch(`https://pokeapi.co/api/v2/pokemon/${id}`);
              if (resp.ok) {
                const data = await resp.json();
                name = data.name;
                image = data.sprites.front_default;
                metadataCache[id] = { name, image };
              }
            } catch (e) {
              // ignore metadata errors
            }
          }
          return { tokenId: id, owner, price, seller, name, image };
        })
      );
      setNfts(results);
    } catch (err: any) {
      setError(err.message || 'Failed to fetch NFTs');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNFTs();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [provider, refreshKey]);

  // Action handlers
  const handleMint = async (tokenId: string) => {
    if (!provider) return;
    setTxStatus({ id: tokenId, msg: 'Minting...' });
    try {
      const signer = await provider.getSigner();
      const nft = new Contract(POKEMAN_NFT_ADDRESS!, PokemanNFTAbi.abi, signer);
      const tx = await nft.mint(tokenId); // adjust if your mint function needs different args
      await tx.wait();
      setTxStatus({ id: tokenId, msg: 'Minted!' });
      handleRefresh();
    } catch (err: any) {
      setTxStatus({ id: tokenId, msg: 'Mint failed: ' + (err.reason || err.message) });
    }
  };

  const handleBuy = async (tokenId: string, price: string) => {
    if (!provider) return;
    setTxStatus({ id: tokenId, msg: 'Approving POKE tokens...' });
    try {
      const signer = await provider.getSigner();
      const pokeToken = new Contract(process.env.REACT_APP_POKETOKEN_ADDRESS!, PokeTokenAbi.abi, signer);
      console.log("I am here!")
      // First approve POKE tokens
      const approveTx = await pokeToken.approve(POKEMAN_MARKETPLACE_ADDRESS, price);
      await approveTx.wait();
      
      setTxStatus({ id: tokenId, msg: 'Buying...' });
      const market = new Contract(POKEMAN_MARKETPLACE_ADDRESS!, PokemanMarketplaceAbi.abi, signer);
      const tx = await market.buy(tokenId); 
      await tx.wait();
      setTxStatus({ id: tokenId, msg: 'Bought!' });
      handleRefresh();
    } catch (err: any) {
      setTxStatus({ id: tokenId, msg: 'Buy failed: ' + (err.reason || err.message) });
    }
  };

  const handleList = async (tokenId: string) => {
    if (!provider) return;
    const price = prompt('Enter price in POKE:');
    if (!price || isNaN(Number(price))) {
      setTxStatus({ id: tokenId, msg: 'Invalid price' });
      return;
    }
    setTxStatus({ id: tokenId, msg: 'Approving NFT transfer...' });
    try {
      const signer = await provider.getSigner();
      const nft = new Contract(POKEMAN_NFT_ADDRESS!, PokemanNFTAbi.abi, signer);
      
      // First approve NFT transfer
      const approveTx = await nft.approve(POKEMAN_MARKETPLACE_ADDRESS, tokenId);
      await approveTx.wait();
      
      setTxStatus({ id: tokenId, msg: 'Listing...' });
      const market = new Contract(POKEMAN_MARKETPLACE_ADDRESS!, PokemanMarketplaceAbi.abi, signer);
      const tx = await market.list(tokenId, price);
      await tx.wait();
      setTxStatus({ id: tokenId, msg: 'Listed!' });
      handleRefresh();
    } catch (err: any) {
      setTxStatus({ id: tokenId, msg: 'List failed: ' + (err.reason || err.message) });
    }
  };

  if (loading) return <div>Loading NFTs...</div>;
  if (error) return <div className="error-message">{error}</div>;
  if (!nfts.length) return <div>No NFTs found.</div>;

  return (
    <div className="gallery">
      {nfts.map((nft) => {
        const isOwner = nft.owner && userAddress && nft.owner.toLowerCase() === userAddress.toLowerCase();
        return (
          <div key={nft.tokenId} className="nft-card">
            <div className="nft-image-container">
              {nft.image && <img src={nft.image} alt={nft.name} className="nft-image" />}
            </div>
            <div className="nft-info">
              <div className="nft-title">
                #{nft.tokenId} {nft.name && `- ${nft.name}`}
              </div>
              <div className="nft-owner">
                Owner: {nft.owner ? truncateAddress(nft.owner) : <span className="unminted-owner">Not minted</span>}
              </div>
              {nft.price && <div className="nft-price">Price: {nft.price} POKE</div>}
            </div>
            {/* Action buttons */}
            <div className="action-buttons">
              {nft.owner === null && (
                <button onClick={() => handleMint(nft.tokenId)} className="btn-mint">Mint</button>
              )}
              {nft.owner && nft.price && !isOwner && (
                <button onClick={() => handleBuy(nft.tokenId, nft.price)} className="btn-buy">Buy</button>
              )}
              {isOwner && (!nft.price || nft.price === '0') && (
                <button onClick={() => handleList(nft.tokenId)} className="btn-list">List</button>
              )}
            </div>
            {/* Transaction status */}
            {txStatus && txStatus.id === nft.tokenId && (
              <div className="tx-status">{txStatus.msg}</div>
            )}
          </div>
        );
      })}
    </div>
  );
};

export default NFTGallery;
