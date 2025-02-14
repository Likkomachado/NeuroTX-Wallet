#!/bin/bash
gunicorn -b 0.0.0.0:5000 Neurotx_Wallet_Colab:app
