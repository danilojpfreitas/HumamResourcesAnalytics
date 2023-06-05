#!/usr/bin/env bash

install() {
    echo "Install Anaconda..."
    sudo apt-get update
    cd /tmp
    sudo apt-get install wget
    wget https://repo.anaconda.com/archive/Anaconda3-2022.05-Linux-x86_64.sh
    sha256sum Anaconda3-2022.05-Linux-x86_64.sh
    bash Anaconda3-2022.05-Linux-x86_64.sh
    cd .

    echo "Install MySQL Docker Container..."
    docker run --name mysqlbd1 -e MYSQL_ROOT_PASSWORD=stack -p "3307:3306" -d mysql
    
    echo "Install Minio Container"
    docker run --name minio -d -p 9000:9000 -p 9001:9001 -v "$PWD/datalake:/data" minio/minio server /data --console-address ":9001"

    echo "Install Airflow Docker Container..."
    docker run -d -p 8080:8080 -v "$PWD/airflow/dags:/opt/airflow/dags/" --entrypoint=/bin/bash --name airflow apache/airflow:2.1.1-python3.8 -c '(airflow db init && airflow users create --username admin --password stack --firstname Danilo --lastname Lastname --role Admin --email admin@example.org); airflow webserver & airflow scheduler'

    #Conectando ao Container do Airflow
    docker container exec -it airflow bash
    #Instalando as bibliotecas para não ter erros nas Dags
    pip install pymysql xlrd openpyxl minio
    #Adicionando as variaveis no Airflow
    # data_lake_server = 172.17.0.1:9000
    # data_lake_login = minioadmin
    # data_lake_password = minioadmin
    # database_server = 172.17.0.3 ( Use o comando inspect para descobrir o ip do
    # container: docker container inspect mysqlbd1 - localizar o atributo IPAddress)
    # database_login = root
    # database_password = stack
    # database_name = employees

    echo "Install Anaconda Docker Container..."
    docker run -i -t -p 8888:8888 continuumio/anaconda3 /bin/bash -c "\
    conda install jupyter -y --quiet && \
    mkdir -p /opt/notebooks && \
    jupyter notebook \
    --notebook-dir=/opt/notebooks --ip='*' --port=8888 \
    --no-browser --allow-root"
    #Para acessar o Jupyter Notebook com os arquivos locais
    jupyter notebook --ip 0.0.0.0 --port 8888 --no-browser --allow-root
}