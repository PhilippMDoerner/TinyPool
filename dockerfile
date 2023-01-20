FROM ubuntu:devel

RUN apt-get update && apt-get install -y curl xz-utils g++ git make
ENV OPENSSLDIR=/usr/local/ssl

# Build OpenSSL 1 from source
RUN mkdir -p $OPENSSLDIR/src
WORKDIR $OPENSSLDIR/src
RUN git clone https://github.com/openssl/openssl.git --depth 1 -b OpenSSL_1_1_1-stable .
RUN ./config --prefix=$OPENSSLDIR --openssldir=$OPENSSLDIR && make && make install
RUN ls $OPENSSLDIR/*
RUN echo "$OPENSSLDIR/lib" > /etc/ld.so.conf.d/openssl.conf
RUN ldconfig

WORKDIR /root/
RUN curl https://nim-lang.org/choosenim/init.sh -sSf | bash -s -- -y
ENV PATH=/root/.nimble/bin:$PATH
RUN choosenim devel

WORKDIR /usr/src/app

COPY . /usr/src/app

RUN git config --global --add safe.directory /usr/src/app

RUN apt-get update 
RUN apt-get install -y sqlite3 
RUN apt-get install -y postgresql-client 
RUN apt-get install -y default-libmysqlclient-dev

RUN nimble install -y