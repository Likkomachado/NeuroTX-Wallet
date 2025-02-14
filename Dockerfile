# Usando a imagem oficial do Python
FROM python:3.10

# Definir diretório de trabalho
WORKDIR /app

# Copiar os arquivos do projeto para dentro do contêiner
COPY . .

# Instalar dependências
RUN pip install --no-cache-dir -r requirements.txt

# Expor a porta 5000
EXPOSE 5000

# Comando para rodar a aplicação
CMD ["gunicorn", "-b", "0.0.0.0:5000", "Neurotx_Wallet_Colab:app"]
