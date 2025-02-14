import sqlite3
import hashlib
import json
import time
import os
from ecdsa import SigningKey, SECP256k1
from flask import Flask, request, jsonify
import socket
import requests

app = Flask(__name__)

class CryptoWallet:
    """Carteira cripto para Android, integrada à rede NeuroTX, agora com banco de dados local e suporte para redes Wi-Fi diferentes."""
    def __init__(self):
        self.private_key = SigningKey.generate(curve=SECP256k1)
        self.public_key = self.private_key.verifying_key.to_string().hex()
        self.address = self.generate_address()
        self.db_path = f"wallet_{self.address}.db"
        self.init_db()

    def generate_address(self):
        """Gera um endereço baseado na chave pública."""
        return hashlib.sha256(self.public_key.encode()).hexdigest()
    
    def init_db(self):
        """Inicializa o banco de dados SQLite local para armazenar saldo e transações."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute('''CREATE TABLE IF NOT EXISTS transactions (
                          id INTEGER PRIMARY KEY AUTOINCREMENT,
                          sender TEXT,
                          recipient TEXT,
                          amount REAL,
                          timestamp REAL,
                          signature TEXT)''')
        cursor.execute('''CREATE TABLE IF NOT EXISTS balance (
                          id INTEGER PRIMARY KEY,
                          amount REAL)''')
        cursor.execute("INSERT OR IGNORE INTO balance (id, amount) VALUES (1, 0.0)")
        conn.commit()
        conn.close()
    
    def get_balance(self):
        """Obtém o saldo da carteira."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT amount FROM balance WHERE id=1")
        balance = cursor.fetchone()[0]
        conn.close()
        return balance

    def update_balance(self, new_balance):
        """Atualiza o saldo da carteira."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute("UPDATE balance SET amount = ? WHERE id=1", (new_balance,))
        conn.commit()
        conn.close()
    
    def sign_transaction(self, transaction):
        """Assina uma transação com a chave privada."""
        transaction_string = json.dumps(transaction, sort_keys=True).encode()
        return self.private_key.sign(transaction_string).hex()
    
    def verify_signature(self, transaction, signature):
        """Verifica a assinatura de uma transação."""
        transaction_string = json.dumps(transaction, sort_keys=True).encode()
        try:
            return self.private_key.verifying_key.verify(bytes.fromhex(signature), transaction_string)
        except:
            return False
    
    def create_transaction(self, recipient, amount):
        """Cria e assina uma nova transação, garantindo que o saldo esteja atualizado."""
        current_balance = self.get_balance()
        if amount > current_balance:
            return "Saldo insuficiente"
        
        transaction = {
            "sender": self.address,
            "recipient": recipient,
            "amount": amount,
            "timestamp": time.time()
        }
        signature = self.sign_transaction(transaction)
        transaction["signature"] = signature
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute("INSERT INTO transactions (sender, recipient, amount, timestamp, signature) VALUES (?, ?, ?, ?, ?)",
                       (self.address, recipient, amount, transaction["timestamp"], signature))
        conn.commit()
        conn.close()
        
        self.update_balance(current_balance - amount)
        return transaction
    
    def receive_funds(self, amount):
        """Recebe fundos e atualiza o saldo da carteira."""
        current_balance = self.get_balance()
        self.update_balance(current_balance + amount)

wallet = CryptoWallet()

@app.route("/balance", methods=["GET"])
def get_balance():
    return jsonify({"address": wallet.address, "balance": wallet.get_balance()})

@app.route("/transaction", methods=["POST"])
def send_transaction():
    data = request.json
    recipient = data.get("recipient")
    amount = data.get("amount")
    transaction = wallet.create_transaction(recipient, amount)
    return jsonify(transaction)

@app.route("/receive", methods=["POST"])
def receive_funds():
    data = request.json
    amount = data.get("amount")
    wallet.receive_funds(amount)
    return jsonify({"message": "Fundos recebidos", "balance": wallet.get_balance()})

@app.route("/public-ip", methods=["GET"])
def get_public_ip():
    """Retorna o IP público da carteira para permitir conexões entre diferentes redes Wi-Fi."""
    try:
        public_ip = requests.get("https://api64.ipify.org?format=json").json()["ip"]
        return jsonify({"public_ip": public_ip})
    except:
        return jsonify({"error": "Falha ao obter IP público"})

if __name__ == "__main__":
    local_ip = socket.gethostbyname(socket.gethostname())
    print(f"Servidor rodando na rede local: http://{local_ip}:5000")
    print("Para acessar de outra rede Wi-Fi, obtenha o IP público via /public-ip e configure o roteador para redirecionar a porta 5000.")
    app.run(host="0.0.0.0", port=5000)
