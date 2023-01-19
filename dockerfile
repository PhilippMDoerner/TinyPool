FROM nimlang/nim:1.6.10

WORKDIR /usr/src/app

COPY . /usr/src/app

RUN apt-get update 
RUN apt-get install -y sqlite3 
RUN apt-get install -y postgresql-client 
RUN apt-get install -y default-libmysqlclient-dev

RUN nimble install -y