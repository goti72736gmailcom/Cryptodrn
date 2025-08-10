# This cell will create the downloadable files the user asked for.
# We'll write: 
# - MultiOwnerWallet.sol
# - MultiOwnerWalletABI.json
# - backend.py
# - requirements.txt
# - qw1.html (integrated frontend)
# - README.txt

multi_owner_wallet_sol = r'''// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title MultiOwner BNB & Token Wallet for BSC
/// @notice Works as a BNB + BEP20 Token wallet with transaction tracking
interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract MultiOwnerWallet {
    struct Owner {
        bool isOwner;
        uint256 addedAt;
    }

    struct TransferRecord {
        address token;        // address(0) for BNB, token address for BEP20
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
        string note;
    }

    mapping(address => Owner) public owners;
    uint256 public ownerCount;
    TransferRecord[] public transfers;

    event OwnerAdded(address indexed newOwner, uint256 time);
    event OwnerRemoved(address indexed removedOwner, uint256 time);
    event BNBSent(address indexed from, address indexed to, uint256 amount, string note);
    event TokenSent(address indexed from, address indexed to, address indexed token, uint256 amount, string note);
    event BNBReceived(address indexed from, uint256 amount);

    modifier onlyOwner() {
        require(owners[msg.sender].isOwner, "Not an owner");
        _;
    }

    constructor(address[] memory initialOwners) {
        require(initialOwners.length > 0, "At least 1 owner required");
        for (uint256 i = 0; i < initialOwners.length; i++) {
            owners[initialOwners[i]] = Owner(true, block.timestamp);
            ownerCount++;
            emit OwnerAdded(initialOwners[i], block.timestamp);
        }
    }

    // --- Owner Management ---
    function addOwner(address newOwner) external onlyOwner {
        require(!owners[newOwner].isOwner, "Already an owner");
        owners[newOwner] = Owner(true, block.timestamp);
        ownerCount++;
        emit OwnerAdded(newOwner, block.timestamp);
    }

    function removeOwner(address existingOwner) external onlyOwner {
        require(owners[existingOwner].isOwner, "Not an owner");
        require(ownerCount > 1, "At least 1 owner required");
        delete owners[existingOwner];
        ownerCount--;
        emit OwnerRemoved(existingOwner, block.timestamp);
    }

    // --- BNB Handling ---
    receive() external payable {
        emit BNBReceived(msg.sender, msg.value);
    }

    function sendBNB(address payable to, uint256 amount, string calldata note) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient BNB balance");
        to.transfer(amount);
        transfers.push(TransferRecord(address(0), msg.sender, to, amount, block.timestamp, note));
        emit BNBSent(msg.sender, to, amount, note);
    }

    function getBNBBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- BEP20 Token Handling ---
    function sendToken(address tokenAddress, address to, uint256 amount, string calldata note) external onlyOwner {
        IBEP20 token = IBEP20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");
        require(token.transfer(to, amount), "Token transfer failed");
        transfers.push(TransferRecord(tokenAddress, msg.sender, to, amount, block.timestamp, note));
        emit TokenSent(msg.sender, to, tokenAddress, amount, note);
    }

    function getTokenBalance(address tokenAddress) public view returns (uint256) {
        IBEP20 token = IBEP20(tokenAddress);
        return token.balanceOf(address(this));
    }

    // --- Transaction History ---
    function getTransfersCount() public view returns (uint256) {
        return transfers.length;
    }

    function getTransfer(uint256 index) public view returns (
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 timestamp,
        string memory note
    ) {
        require(index < transfers.length, "Invalid index");
        TransferRecord memory t = transfers[index];
        return (t.token, t.from, t.to, t.amount, t.timestamp, t.note);
    }

    function getAllTransfers() public view returns (TransferRecord[] memory) {
        return transfers;
    }
}
'''

# ABI crafted for the above contract
multi_owner_wallet_abi = [
  {
    "inputs": [
      {
        "internalType": "address[]",
        "name": "initialOwners",
        "type": "address[]"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "anonymous": False,
    "inputs": [
      {"indexed": True, "internalType": "address", "name": "from", "type": "address"},
      {"indexed": True, "internalType": "address", "name": "to", "type": "address"},
      {"indexed": False, "internalType": "uint256", "name": "amount", "type": "uint256"},
      {"indexed": False, "internalType": "string", "name": "note", "type": "string"}
    ],
    "name": "BNBSent",
    "type": "event"
  },
  {
    "anonymous": False,
    "inputs": [
      {"indexed": True, "internalType": "address", "name": "from", "type": "address"},
      {"indexed": False, "internalType": "uint256", "name": "amount", "type": "uint256"}
    ],
    "name": "BNBReceived",
    "type": "event"
  },
  {
    "anonymous": False,
    "inputs": [
      {"indexed": True, "internalType": "address", "name": "newOwner", "type": "address"},
      {"indexed": False, "internalType": "uint256", "name": "time", "type": "uint256"}
    ],
    "name": "OwnerAdded",
    "type": "event"
  },
  {
    "anonymous": False,
    "inputs": [
      {"indexed": True, "internalType": "address", "name": "removedOwner", "type": "address"},
      {"indexed": False, "internalType": "uint256", "name": "time", "type": "uint256"}
    ],
    "name": "OwnerRemoved",
    "type": "event"
  },
  {
    "anonymous": False,
    "inputs": [
      {"indexed": True, "internalType": "address", "name": "from", "type": "address"},
      {"indexed": True, "internalType": "address", "name": "to", "type": "address"},
      {"indexed": True, "internalType": "address", "name": "token", "type": "address"},
      {"indexed": False, "internalType": "uint256", "name": "amount", "type": "uint256"},
      {"indexed": False, "internalType": "string", "name": "note", "type": "string"}
    ],
    "name": "TokenSent",
    "type": "event"
  },
  {
    "inputs": [{"internalType": "address", "name": "newOwner", "type": "address"}],
    "name": "addOwner",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getBNBBalance",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "tokenAddress", "type": "address"}],
    "name": "getTokenBalance",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getTransfersCount",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "", "type": "address"}],
    "name": "owners",
    "outputs": [
      {"internalType": "bool", "name": "isOwner", "type": "bool"},
      {"internalType": "uint256", "name": "addedAt", "type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "existingOwner", "type": "address"}
    ],
    "name": "removeOwner",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "token", "type": "address"},
      {"internalType": "address", "name": "from", "type": "address"},
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "amount", "type": "uint256"},
      {"internalType": "uint256", "name": "timestamp", "type": "uint256"},
      {"internalType": "string", "name": "note", "type": "string"}
    ],
    "name": "TransferRecord",
    "outputs": [],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address payable", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "amount", "type": "uint256"},
      {"internalType": "string", "name": "note", "type": "string"}
    ],
    "name": "sendBNB",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "tokenAddress", "type": "address"},
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "amount", "type": "uint256"},
      {"internalType": "string", "name": "note", "type": "string"}
    ],
    "name": "sendToken",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "name": "transfers",
    "outputs": [
      {"internalType": "address", "name": "token", "type": "address"},
      {"internalType": "address", "name": "from", "type": "address"},
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "amount", "type": "uint256"},
      {"internalType": "uint256", "name": "timestamp", "type": "uint256"},
      {"internalType": "string", "name": "note", "type": "string"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256", "name": "index", "type": "uint256"}],
    "name": "getTransfer",
    "outputs": [
      {"internalType": "address", "name": "token", "type": "address"},
      {"internalType": "address", "name": "from", "type": "address"},
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "amount", "type": "uint256"},
      {"internalType": "uint256", "name": "timestamp", "type": "uint256"},
      {"internalType": "string", "name": "note", "type": "string"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "ownerCount",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  }
]

backend_py = r'''from flask import Flask, request, jsonify, send_from_directory
from web3 import Web3
from flask_cors import CORS
import json, os

app = Flask(_name_, static_folder='.', static_url_path='')
CORS(app)

# -------------------
# CONFIGURATION
# -------------------
# Default to BSC Testnet; change to mainnet RPC if needed
BSC_RPC = os.getenv("BSC_RPC", "https://data-seed-prebsc-1-s1.binance.org:8545")
PRIVATE_KEY = os.getenv("PRIVATE_KEY")          # put in environment, never commit
OWNER_ADDRESS = os.getenv("OWNER_ADDRESS")      # checksum address of the owner key
CONTRACT_ADDRESS = os.getenv("CONTRACT_ADDRESS")# deployed MultiOwnerWallet address

if not (PRIVATE_KEY and OWNER_ADDRESS and CONTRACT_ADDRESS):
    print("WARNING: Set PRIVATE_KEY, OWNER_ADDRESS, CONTRACT_ADDRESS environment variables.")

# Connect Web3
w3 = Web3(Web3.HTTPProvider(BSC_RPC))
assert w3.is_connected(), "Web3 not connected. Check RPC."

# Load ABI
with open("MultiOwnerWalletABI.json") as f:
    CONTRACT_ABI = json.load(f)

contract = w3.eth.contract(address=Web3.to_checksum_address(CONTRACT_ADDRESS), abi=CONTRACT_ABI)

# -------------------
# STATIC (serve qw1.html as index)
# -------------------
@app.route('/')
def index():
    return send_from_directory('.', 'qw1.html')

# -------------------
# API ROUTES
# -------------------

@app.route("/api/wallet", methods=["GET"])
def get_wallet_info():
    try:
        bnb_balance_wei = contract.functions.getBNBBalance().call()
        bnb_balance_eth = float(w3.fromWei(bnb_balance_wei, "ether"))
        # Stub price; replace with your own price feed if needed
        bnb_price = float(os.getenv("BNB_PRICE", "300"))
        usd_balance = bnb_balance_eth * bnb_price

        return jsonify({
            "bnbBalance": f"{bnb_balance_eth:.6f}",
            "usdBalance": usd_balance,
            "bnbPrice": bnb_price
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/send", methods=["POST"])
def send_bnb():
    data = request.get_json(force=True)
    recipient = data.get("recipient")
    amount = data.get("amount")  # in BNB (float or str)

    try:
        if not recipient or amount is None:
            return jsonify({"success": False, "error": "recipient and amount required"}), 400

        sender = Web3.to_checksum_address(OWNER_ADDRESS)
        nonce = w3.eth.get_transaction_count(sender)

        txn = contract.functions.sendBNB(
            Web3.to_checksum_address(recipient),
            w3.toWei(float(amount), "ether"),
            "Sent from Flask API"
        ).build_transaction({
            "from": sender,
            "nonce": nonce,
            "gas": 300000,
            "gasPrice": w3.toWei("5", "gwei")
        })

        signed = w3.eth.account.sign_transaction(txn, private_key=PRIVATE_KEY)
        tx_hash = w3.eth.send_raw_transaction(signed.rawTransaction)
        return jsonify({"success": True, "txHash": tx_hash.hex()})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

if _name_ == "_main_":
    app.run(host="0.0.0.0", port=8000, debug=True)
'''

requirements_txt = """flask==3.0.2
flask-cors==4.0.0
web3==6.19.0
"""

# Integrated qw1.html: based on user's file with backend fetch calls
qw1_integrated_html = r'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wallet UI Showcase</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-primary: #1E1E1E;
            --bg-secondary: #2C2C2C;
            --bg-tertiary: #121212;
            --text-primary: #EAEAEA;
            --text-secondary: #8E8E8E;
            --accent-green: #33D179;
            --accent-green-dark: #29a862;
            --accent-red: #ff4d4d;
            --border-color: #3A3A3A;
            --warning-bg: #3a3224;
            --warning-text: #f3ba2f;

            --light-bg: #FFFFFF;
            --light-text-primary: #000000;
            --light-text-secondary: #6B7280;
            --light-accent-blue: #007AFF;
            --light-accent-green: #10B981;
            --light-border: #F3F4F6;
            --light-app-bg: #F9FAFB;
        }
        body { background-color: var(--bg-primary); color: var(--text-primary); font-family: 'Inter', sans-serif; margin: 0; padding: 0; min-height: 100vh; overflow: hidden; }
        .wallet-container { width: 100vw; height: 100vh; background-color: var(--bg-primary); display: flex; flex-direction: column; overflow: hidden; }
        .window-header { display: flex; justify-content: space-between; align-items: center; padding: 10px 20px; background-color: var(--bg-tertiary); border-bottom: 1px solid var(--border-color); flex-shrink: 0; }
        .window-header span { font-size: 14px; font-weight: 500; }
        .window-header .close-btn { cursor: pointer; font-weight: bold; }
        .screen { padding: 0; flex-grow: 1; display: flex; flex-direction: column; overflow-y: auto; background-color: var(--bg-primary); }
        .screen-header { display: flex; align-items: center; gap: 30px; padding: 30px 60px; position: sticky; top: 0; background-color: var(--bg-primary); z-index: 10; }
        .back-btn { font-size: 24px; font-weight: 300; cursor: pointer; }
        .screen-header h2 { margin: 0; font-size: 20px; font-weight: 600; }
        #main-wallet-screen { gap: 20px; }
        .main-content { padding: 40px 60px 0 60px; display: flex; flex-direction: column; gap: 30px; }
        .warning-banner { background-color: var(--warning-bg); color: var(--warning-text); padding: 12px 20px; border-radius: 8px; display: flex; align-items: center; justify-content: space-between; font-size: 14px; font-weight: 500; cursor: pointer; }
        .warning-banner i { margin-right: 10px; }
        .account-header { display: flex; justify-content: space-between; align-items: center; }
        .account-name { font-weight: 600; cursor: pointer; }
        .account-name i { font-size: 12px; margin-left: 5px; }
        .header-icons { display: flex; align-items: center; gap: 15px; }
        .header-icons i { font-size: 18px; cursor: pointer; color: var(--text-secondary); }
        .header-icons .youtube-icon { color: var(--accent-red); font-size: 20px; background-color: white; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; }
        .header-icons .youtube-icon i { color: var(--accent-red); font-size: 14px;}
        .account-details { text-align: left; margin-top: -10px; }
        .account-details p { margin: 0; color: var(--text-secondary); font-size: 14px; }
        .account-details h1 { font-size: 64px; margin: 5px 0; font-weight: 600; display: inline-flex; align-items: center; gap: 20px; }
        .account-details h1 i { font-size: 16px; color: var(--text-secondary); font-weight: normal; cursor: pointer; }
        .main-actions { display: flex; justify-content: space-around; text-align: center; }
        .action-btn { display: flex; flex-direction: column; align-items: center; gap: 12px; cursor: pointer; color: var(--text-primary); }
        .action-btn .icon-wrapper { background-color: var(--bg-secondary); width: 80px; height: 80px; border-radius: 50%; display: flex; justify-content: center; align-items: center; font-size: 32px; }
        .action-btn span { font-weight: 500; font-size: 14px; }
        .tabs { display: flex; border-bottom: 1px solid var(--border-color); margin-bottom: 20px; padding: 0 60px; }
        .tab { padding: 15px 20px; margin: 0 10px; cursor: pointer; color: var(--text-secondary); font-weight: 600; position: relative; }
        .tab:first-child { margin-left: 0; }
        .tab.active { color: var(--text-primary); }
        .tab.active::after { content: ''; position: absolute; bottom: -1px; left: 0; right: 0; height: 2px; background-color: var(--accent-green); }
        .token-list-container { padding: 0 60px; }
        .token-list { display: flex; flex-direction: column; gap: 5px; }
        .token-item { display: flex; justify-content: space-between; align-items: center; padding: 15px 10px; cursor: pointer; border-radius: 8px; transition: background-color 0.2s; }
        .token-item:hover { background-color: var(--bg-secondary); }
        .token-item-info { display: flex; align-items: center; gap: 15px; }
        .token-icon { width: 42px; height: 42px; border-radius: 50%; }
        .token-icon img { width: 100%; height: 100%; border-radius: 50%; }
        .token-details h3 { margin: 0 0 4px 0; font-size: 16px; font-weight: 500; }
        .token-details h3 .chain-tag { background-color: var(--bg-secondary); color: var(--text-secondary); padding: 3px 8px; border-radius: 6px; font-size: 12px; margin-left: 8px; font-weight: 400; }
        .token-details p { margin: 0; color: var(--text-secondary); font-size: 14px; }
        .token-details .price-change { color: var(--accent-green); }
        .token-balance { text-align: right; }
        .token-balance .amount { font-size: 16px; font-weight: 500; margin-bottom: 4px; }
        .token-balance .value { color: var(--text-secondary); font-size: 14px; }
        .manage-crypto-link { text-align: center; color: var(--accent-green); font-weight: 600; cursor: pointer; margin-top: 15px; padding-bottom: 20px; }
        .footer-nav { display: flex; justify-content: space-around; padding: 10px 0; background-color: var(--bg-secondary); border-top: 1px solid var(--border-color); margin-top: auto; flex-shrink: 0; }
        .nav-item { display: flex; flex-direction: column; align-items: center; gap: 6px; color: var(--text-secondary); font-size: 12px; cursor: pointer; }
        .nav-item.active { color: var(--accent-green); }
        .nav-item i { font-size: 20px; }
        #select-asset-screen .content { padding: 0 60px 30px 60px; }
        .search-bar-wrapper { background-color: var(--bg-secondary); border-radius: 20px; padding: 10px 15px; display: flex; align-items: center; gap: 10px; margin-bottom: 20px; }
        .search-bar-wrapper i { color: var(--text-secondary); }
        .search-bar-wrapper input { background: none; border: none; color: var(--text-primary); font-size: 14px; width: 100%; }
        .search-bar-wrapper input:focus { outline: none; }
        .network-filter { display: flex; align-items: center; gap: 10px; padding: 8px 12px; background-color: var(--bg-secondary); border-radius: 8px; cursor: pointer; margin-bottom: 15px; width: fit-content; }
        .network-filter img { width: 24px; height: 24px; }
        .network-filter span { font-weight: 500; }
        .network-filter i { font-size: 12px; color: var(--text-secondary); }
        #send-bnb-screen { padding: 0 60px 30px 60px; }
        #send-bnb-screen .network-info { text-align: center; margin-bottom: 30px; font-size: 14px; color: var(--text-secondary); display: flex; flex-direction: column; align-items: center; gap: 10px; }
        #send-bnb-screen .network-info .token-icon { width: 42px; height: 42px; }
        #send-bnb-screen form { display: flex; flex-direction: column; gap: 25px; flex-grow: 1; }
        .form-group { position: relative; }
        .form-group label { display: block; color: var(--text-primary); font-size: 14px; font-weight: 600; margin-bottom: 12px; }
        .input-wrapper { background-color: var(--bg-primary); border: 1px solid var(--border-color); border-radius: 12px; padding: 15px; display: flex; align-items: center; transition: border-color 0.2s; }
        .input-wrapper:focus-within, .input-wrapper.active { border-color: var(--accent-green); }
        .input-wrapper input { background: none; border: none; color: var(--text-primary); font-size: 16px; width: 100%; font-family: 'Inter', sans-serif; }
        .input-wrapper input::placeholder { color: var(--text-secondary); }
        .input-wrapper input:focus { outline: none; }
        .paste-btn, .max-btn { background: none; border: none; color: var(--accent-green); cursor: pointer; font-weight: bold; font-size: 14px; }
        .paste-btn i { font-size: 18px; }
        .balance-info { color: var(--text-secondary); font-size: 14px; margin-top: 10px; padding-left: 5px; }
        .preview-btn { background-color: var(--accent-green-dark); color: var(--bg-tertiary); border: none; padding: 18px; border-radius: 25px; font-size: 18px; font-weight: 600; cursor: not-allowed; margin-top: auto; margin-bottom: 20px; opacity: 0.5; text-align: center; transition: background-color 0.3s, opacity 0.3s; }
        .preview-btn.active { background-color: var(--accent-green); color: white; opacity: 1; cursor: pointer; }
        .light-wallet-container { width: 600px; height: 500px; background-color: var(--light-bg); border-radius: 16px; box-shadow: 0 8px 30px rgba(0, 0, 0, 0.1); display: flex; flex-direction: column; padding: 20px; font-family: 'Inter', sans-serif; flex-shrink: 0; color: var(--light-text-primary); }
        .light-wallet-header { display: flex; justify-content: space-between; align-items: center; padding: 10px 4px; }
        .light-wallet-header .close-icon { font-size: 24px; font-weight: bold; color: var(--light-text-secondary); cursor: pointer; }
        .light-wallet-header .title { font-size: 18px; font-weight: 600; color: var(--light-text-primary); }
        .transfer-content { flex-grow: 1; display: flex; flex-direction: column; padding: 16px; }
        .amount-display { text-align: center; margin: 40px 0; }
        .amount-display .trx-amount { font-size: 36px; font-weight: 700; color: var(--light-text-primary); letter-spacing: -0.5px; }
        .amount-display .inr-equivalent { font-size: 16px; color: var(--light-text-secondary); margin-top: 8px; }
        .details-box { background-color: var(--light-app-bg); border-radius: 12px; padding: 8px 16px; }
        .detail-row { display: flex; justify-content: space-between; align-items: center; padding: 16px 0; border-bottom: 1px solid var(--light-border); }
        .detail-row:last-child { border-bottom: none; }
        .detail-row .label { font-size: 16px; color: var(--light-text-secondary); }
        .detail-row .value { font-size: 16px; font-weight: 500; color: var(--light-text-primary); display: flex; align-items: center; text-align: right; }
        .detail-row .value.discount { color: var(--light-accent-green); font-weight: 600; }
        .detail-row .fee-details { display: flex; flex-direction: column; align-items: flex-end; }
        .detail-row .fee-details .fee-value { font-size: 14px; color: var(--light-text-secondary); }
        .total-section { display: flex; justify-content: space-between; align-items: center; padding: 24px 16px; }
        .total-section .label { font-size: 18px; font-weight: 500; color: var(--light-text-primary); }
        .total-section .value { font-size: 18px; font-weight: 600; color: var(--light-text-primary); }
        .confirm-button { background-color: var(--light-accent-blue); color: white; border: none; width: 100%; padding: 16px; border-radius: 100px; font-size: 18px; font-weight: 600; cursor: pointer; margin-top: auto; transition: background-color 0.2s; }
        .confirm-button:hover { background-color: #0056b3; }
        #preview-modal { position: fixed; display: none; width: 100%; height: 100%; top: 0; left: 0; right: 0; bottom: 0; background-color: rgba(0,0,0,0.5); z-index: 1000; justify-content: center; align-items: center; -webkit-backdrop-filter: blur(5px); backdrop-filter: blur(5px); }
    </style>
</head>
<body>
    <div class="wallet-container">
        <header class="window-header">
            <span>Trust Wallet</span>
            <span class="close-btn">X</span>
        </header>

        <!-- Screen 1: Main Wallet View -->
        <div id="main-wallet-screen" class="screen">
            <div class="main-content">
                <div class="warning-banner">
                    <div><i class="fas fa-exclamation-triangle"></i><span>Backup your Secret Phrase now</span></div>
                    <span>&gt;</span>
                </div>
                <div class="account-header">
                    <div class="account-name">Mnemonic 1 <i class="fas fa-chevron-down"></i></div>
                    <div class="header-icons">
                        <span class="youtube-icon"><i class="fas fa-play"></i></span>
                        <i class="fas fa-wallet"></i><i class="far fa-copy"></i><i class="fas fa-search"></i><i class="fas fa-ellipsis-h"></i>
                    </div>
                </div>
                <div class="account-details">
                    <p>Account 1</p>
                    <h1>$0.00 <i class="fas fa-sync-alt"></i><i class="fas fa-cog"></i></h1>
                </div>
                <div class="main-actions">
                    <div id="action-send" class="action-btn">
                        <div class="icon-wrapper"><i class="fas fa-arrow-up"></i></div>
                        <span>Send</span>
                    </div>
                    <div class="action-btn"><div class="icon-wrapper"><i class="fas fa-arrow-down"></i></div><span>Receive</span></div>
                    <div class="action-btn"><div class="icon-wrapper"><i class="fas fa-exchange-alt"></i></div><span>Swap</span></div>
                    <div class="action-btn"><div class="icon-wrapper"><i class="fas fa-credit-card"></i></div><span>Buy & Sell</span></div>
                </div>
            </div>
            <div>
                <div class="tabs"><div class="tab active">Crypto</div><div class="tab">NFTs</div></div>
                <div class="token-list-container">
                    <section class="token-list">
                        <div class="token-item asset-to-send">
                            <div class="token-item-info">
                                <div class="token-icon"><img src="https://s2.coinmarketcap.com/static/img/coins/64x64/1839.png" alt="BNB"></div>
                                <div class="token-details"><h3>BNB <span class="chain-tag">BNB Smart Chain</span></h3><p>$0.00 <span class="price-change">+0.00%</span></p></div>
                            </div>
                            <div class="token-balance"><p class="amount">0</p><p class="value">$0.00</p></div>
                        </div>
                    </section>
                    <div class="manage-crypto-link">Manage crypto</div>
                </div>
            </div>
            <nav class="footer-nav">
                <div class="nav-item active"><i class="fas fa-home"></i><span>Home</span></div>
                <div class="nav-item"><i class="fas fa-chart-pie"></i><span>Earn</span></div>
                <div class="nav-item"><i class="fas fa-history"></i><span>History</span></div>
                <div class="nav-item"><i class="fas fa-cog"></i><span>Settings</span></div>
            </nav>
        </div>

        <!-- Screen 2: Select Asset to Send -->
        <div id="select-asset-screen" class="screen" style="display: none;">
            <header class="screen-header">
                <span class="back-btn" id="back-to-main-from-select">←</span>
                <h2>Select asset to send</h2>
            </header>
            <main class="content">
                <div class="search-bar-wrapper">
                    <i class="fas fa-search"></i>
                    <input type="text" placeholder="Token name or contract address">
                </div>
                <div class="network-filter">
                    <img src="https://s2.coinmarketcap.com/static/img/coins/64x64/1839.png" alt="BNB">
                    <span>BNB Smart Chain</span>
                    <i class="fas fa-chevron-down"></i>
                </div>
                <section class="token-list">
                    <div class="token-item asset-to-send">
                        <div class="token-item-info">
                            <div class="token-icon"><img src="https://s2.coinmarketcap.com/static/img/coins/64x64/1839.png" alt="BNB"></div>
                            <div class="token-details"><h3>BNB <span class="chain-tag">BNB Smart Chain</span></h3><p>$0.00 <span class="price-change">+0.00%</span></p></div>
                        </div>
                        <div class="token-balance"><p class="amount">0</p><p class="value">$0.00</p></div>
                    </div>
                </section>
            </main>
        </div>
        
        <!-- Screen 3: Send BNB -->
        <div id="send-bnb-screen" class="screen" style="display: none;">
            <header class="screen-header">
                <span class="back-btn" id="back-to-select-from-send">←</span>
                <h2>Send BNB</h2>
            </header>
            <div class="network-info">
                <div class="token-icon"><img src="https://s2.coinmarketcap.com/static/img/coins/64x64/1839.png" alt="BNB"></div>
                <p>on BNB Smart Chain Network</p>
            </div>
            <form onsubmit="return false;">
                <div class="form-group">
                    <label for="recipient-address">Recipient Address</label>
                    <div class="input-wrapper">
                        <input type="text" id="recipient-address" placeholder="Type or paste a valid address">
                        <button type="button" class="paste-btn"><i class="fas fa-qrcode"></i></button>
                    </div>
                </div>
                <div class="form-group">
                    <label for="amount">Amount</label>
                    <div class="input-wrapper">
                        <input type="text" id="amount" placeholder="Type or paste a valid amount">
                        <button type="button" class="max-btn">MAX</button>
                    </div>
                    <p class="balance-info">Balance: 0 BNB</p>
                </div>
                <button type="button" class="preview-btn">Preview</button>
            </form>
        </div>
    </div>

    <!-- Modal container for the preview -->
    <div id="preview-modal">
        <div class="light-wallet-container">
            <header class="light-wallet-header">
                <span class="close-icon" id="close-preview-btn">×</span>
                <span class="title">Transfer</span>
                <span style="width: 18px;"></span>
            </header>
            <main class="transfer-content">
                <div class="amount-display">
                    <div class="trx-amount">-0 BNB</div>
                    <div class="inr-equivalent">≈ $0.00</div>
                </div>
                <div class="details-box">
                    <div class="detail-row">
                        <span class="label">Asset</span>
                        <span class="value">BNB</span>
                    </div>
                    <div class="detail-row">
                        <span class="label">Wallet</span>
                        <span class="value">Contract Wallet<br>0x...yourContract</span>
                    </div>
                    <div class="detail-row">
                        <span class="label">To</span>
                        <span class="value">0x...</span>
                    </div>
                    <div class="detail-row">
                        <span class="label">Network fee</span>
                        <div class="fee-details">
                            <span class="value discount">Varies</span>
                            <span class="fee-value">See wallet prompt</span>
                        </div>
                    </div>
                </div>
                <div class="total-section">
                    <span class="label">Max Total</span>
                    <span class="value">$0.00</span>
                </div>
                <button class="confirm-button">Confirm</button>
            </main>
        </div>
    </div>

    <script>
        // --- Navigation Logic ---
        const mainWalletScreen = document.getElementById('main-wallet-screen');
        const selectAssetScreen = document.getElementById('select-asset-screen');
        const sendBnbScreen = document.getElementById('send-bnb-screen');
        const actionSendBtn = document.getElementById('action-send');
        const assetsToSend = document.querySelectorAll('.asset-to-send');
        const backToMainBtn = document.getElementById('back-to-main-from-select');
        const backToSelectAssetBtn = document.getElementById('back-to-select-from-send');

        actionSendBtn.addEventListener('click', () => {
            mainWalletScreen.style.display = 'none';
            selectAssetScreen.style.display = 'flex';
        });
        assetsToSend.forEach(item => {
            item.addEventListener('click', () => {
                selectAssetScreen.style.display = 'none';
                sendBnbScreen.style.display = 'flex';
            });
        });
        if (backToMainBtn) {
            backToMainBtn.addEventListener('click', () => {
                selectAssetScreen.style.display = 'none';
                mainWalletScreen.style.display = 'flex';
            });
        }
        backToSelectAssetBtn.addEventListener('click', () => {
            sendBnbScreen.style.display = 'none';
            selectAssetScreen.style.display = 'flex';
        });

        // --- Preview Modal Logic ---
        const previewModal = document.getElementById('preview-modal');
        const closePreviewBtn = document.getElementById('close-preview-btn');
        const previewBtn = document.querySelector('.preview-btn');
        const recipientInput = document.getElementById('recipient-address');
        const amountInput = document.getElementById('amount');

        function updatePreviewButtonState() {
            if (recipientInput.value.trim() !== '' && amountInput.value.trim() !== '') {
                previewBtn.classList.add('active');
            } else {
                previewBtn.classList.remove('active');
            }
        }
        recipientInput.addEventListener('input', updatePreviewButtonState);
        amountInput.addEventListener('input', updatePreviewButtonState);

        function setText(selector, text) {
            const el = document.querySelector(selector);
            if (el) el.textContent = text;
        }

        function updatePreviewModal(bnbPrice) {
            const amount = parseFloat(amountInput.value || '0');
            const toAddress = recipientInput.value || '0x...';
            setText('.trx-amount', -${amount} BNB);
            setText('.inr-equivalent', ≈ $${(amount * bnbPrice).toFixed(2)});
            document.querySelectorAll('.detail-row .value')[2].textContent = toAddress;
            setText('.total-section .value', $${(amount * bnbPrice).toFixed(2)});
        }

        previewBtn.addEventListener('click', async () => {
            if (previewBtn.classList.contains('active')) {
                try {
                    const res = await fetch('/api/wallet');
                    const data = await res.json();
                    updatePreviewModal(data.bnbPrice || 300);
                } catch (e) {
                    updatePreviewModal(300);
                }
                previewModal.style.display = 'flex';
            }
        });
        closePreviewBtn.addEventListener('click', () => previewModal.style.display = 'none');
        previewModal.addEventListener('click', (e) => { if (e.target === previewModal) previewModal.style.display = 'none'; });

        // --- Backend Integration ---
        async function loadWalletData() {
            try {
                const res = await fetch('/api/wallet');
                const data = await res.json();
                document.querySelector('.account-details h1').innerHTML =
                    $${parseFloat(data.usdBalance).toFixed(2)} <i class="fas fa-sync-alt"></i><i class="fas fa-cog"></i>;
                document.querySelector('.balance-info').textContent = Balance: ${data.bnbBalance} BNB;

                // Update BNB item
                document.querySelectorAll('.token-list .token-item').forEach(tokenItem => {
                    const name = tokenItem.querySelector('h3').innerText.split(' ')[0];
                    if (name === 'BNB') {
                        tokenItem.querySelector('.token-details p').innerHTML =
                            $${parseFloat(data.bnbPrice).toFixed(2)} <span class="price-change">+0.00%</span>;
                        tokenItem.querySelector('.token-balance .amount').textContent = data.bnbBalance;
                        tokenItem.querySelector('.token-balance .value').textContent =
                            $${(parseFloat(data.bnbBalance) * data.bnbPrice).toFixed(2)};
                    }
                });
            } catch (err) {
                console.error('Error loading wallet data:', err);
            }
        }

        document.querySelector('.confirm-button').addEventListener('click', async () => {
            const address = recipientInput.value.trim();
            const amount = parseFloat(amountInput.value.trim());
            if (!address || !amount) {
                alert('Please enter a valid address and amount');
                return;
            }
            try {
                const res = await fetch('/api/send', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ recipient: address, amount })
                });
                const result = await res.json();
                if (result.success) {
                    alert(Transaction sent! Hash: ${result.txHash});
                    previewModal.style.display = 'none';
                    loadWalletData();
                } else {
                    alert(Error: ${result.error});
                }
            } catch (err) {
                alert('Failed to send transaction.');
                console.error(err);
            }
        });

        // Init
        loadWalletData();
    </script>
</body>
</html>
'''

readme_txt = r'''# Full-stack Wallet (Frontend + Flask + Solidity)

This package contains:
- MultiOwnerWallet.sol — Solidity contract for BNB & BEP20 with multi-owner + history.
- MultiOwnerWalletABI.json — ABI for the contract.
- backend.py — Flask API that talks to the contract via web3.py.
- requirements.txt — Python deps.
- qw1.html — Your wallet UI connected to the backend.

## 1) Deploy the contract (BSC Testnet)
1. Open https://remix.ethereum.org/
2. Create a new file MultiOwnerWallet.sol and paste the contents.
3. Compile with Solidity ^0.8.19.
4. In *Deploy & Run*, select Injected Provider - MetaMask and connect to *BSC Testnet*.
5. Set constructor parameter initialOwners as an array with your address, e.g. ["0xYourAddress"].
6. Deploy. Fund the contract with test BNB (so it can sendBNB).
7. Copy the deployed *contract address*.

## 2) Configure backend
Create a .env or set environment variables: