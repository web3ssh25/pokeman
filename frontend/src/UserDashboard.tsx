import React, { useState, useEffect } from 'react';
import { BrowserProvider, Contract, formatUnits, parseEther } from 'ethers';
import PokeTokenAbi from './abi/PokeToken.json';
import PokemanNFTAbi from './abi/PokemanNFT.json';
import './UserDashboard.css';

interface Props {
  provider: BrowserProvider | null;
  userAddress: string | null;
  refreshKey: number;
  handleRefresh: () => void;
}

const UserDashboard: React.FC<Props> = ({ provider, userAddress, refreshKey, handleRefresh }) => {
  const [stakedAmount, setStakedAmount] = useState('0');
  const [nextMintTime, setNextMintTime] = useState(0);
  const [stakeInput, setStakeInput] = useState('');
  const [status, setStatus] = useState('');
  const [requiredStake, setRequiredStake] = useState('0');
  const [countdown, setCountdown] = useState('');

  const POKE_TOKEN_ADDRESS = process.env.REACT_APP_POKETOKEN_ADDRESS!;
  const POKEMAN_NFT_ADDRESS = process.env.REACT_APP_POKEMANNFT_ADDRESS!;

  const fetchStakingData = async () => {
    if (!provider || !userAddress) return;
    try {
      const nftContract = new Contract(POKEMAN_NFT_ADDRESS, PokemanNFTAbi.abi, provider);
      const [staked, lastMint, coolDown, reqStake] = await Promise.all([
        nftContract.stakedAmount(userAddress),
        nftContract.lastMintTime(userAddress),
        nftContract.coolingPeriod(),
        nftContract.requiredStake()
      ]);
      
      setStakedAmount(formatUnits(staked, 18));
      setRequiredStake(formatUnits(reqStake, 18));

      const nextAvailableTime = Number(lastMint) + Number(coolDown);
      setNextMintTime(nextAvailableTime);
    } catch (err) {
      console.error("Failed to fetch staking data:", err);
    }
  };

  useEffect(() => {
    fetchStakingData();
  }, [provider, userAddress, refreshKey]);

  useEffect(() => {
    if (nextMintTime === 0) return;

    const interval = setInterval(() => {
      const now = Math.floor(Date.now() / 1000);
      const remaining = nextMintTime - now;
      if (remaining > 0) {
        const hours = Math.floor(remaining / 3600);
        const minutes = Math.floor((remaining % 3600) / 60);
        const seconds = remaining % 60;
        setCountdown(`${hours}h ${minutes}m ${seconds}s`);
      } else {
        setCountdown('Ready to mint!');
        clearInterval(interval);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [nextMintTime]);

  const handleStake = async () => {
    if (!provider || !stakeInput || parseFloat(stakeInput) <= 0) {
      setStatus('Please enter a valid amount to stake.');
      return;
    }
    setStatus('Staking...');
    try {
      const signer = await provider.getSigner();
      const pokeToken = new Contract(POKE_TOKEN_ADDRESS, PokeTokenAbi.abi, signer);
      
     // Use parseEther for 18-decimal tokens. It's more idiomatic and robust.
      const amount = parseEther(stakeInput.toString());
      console.log(stakeInput)
      setStatus('Approving token transfer...');
      const approveTx = await pokeToken.approve(POKEMAN_NFT_ADDRESS, stakeInput);
      await approveTx.wait();

       setStatus('Staking tokens...');
       const nftContract = new Contract(POKEMAN_NFT_ADDRESS, PokemanNFTAbi.abi, signer);
       const stakeTx = await nftContract.stake(stakeInput);
       await stakeTx.wait();
      
      setStatus('Stake successful!');
      setStakeInput('');
      handleRefresh();
    } catch (err: any) {
      setStatus('Stake failed: ' + (err.reason || err.message));
    }
  };

  const handleUnstake = async () => {
    if (!provider) return;
    setStatus('Unstaking...');
    try {
      const signer = await provider.getSigner();
      const nftContract = new Contract(POKEMAN_NFT_ADDRESS, PokemanNFTAbi.abi, signer);
      const unstakeTx = await nftContract.unstake();
      await unstakeTx.wait();

      setStatus('Unstake successful!');
      handleRefresh();
    } catch (err: any) {
      setStatus('Unstake failed: ' + (err.reason || err.message));
    }
  };

  return (
    <div className="user-dashboard">
      <h3>Your Staking Dashboard</h3>
      <div className="staking-info">
        <p>Required Stake: <strong>{requiredStake} POKE</strong></p>
        <p>Your Staked Amount: <strong>{stakedAmount} POKE</strong></p>
        <p>Next Mint Available: <strong>{countdown || 'Calculating...'}</strong></p>
      </div>

      <div className="staking-actions">
        <div className="input-group">
          <input
            type="text"
            placeholder="Amount to stake"
            value={stakeInput}
            onChange={(e) => setStakeInput(e.target.value)}
          />
          <button onClick={handleStake} disabled={!stakeInput}>Stake</button>
        </div>
        <button className="unstake-button" onClick={handleUnstake} disabled={stakedAmount === '0.0'}>
          Unstake
        </button>
      </div>
      {status && <p className="status-message">{status}</p>}
    </div>
  );
};

export default UserDashboard; 