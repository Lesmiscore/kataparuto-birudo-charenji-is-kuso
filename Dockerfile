FROM ubuntu:xenial as catapult

RUN apt-get update && apt-get -y install \
      cmake git make automake libzmq-dev gcc g++ \
      librocksdb-dev tar wget libtool libboost-all-dev

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 && \
    echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list && \
    apt-get update && apt-get -y install \
      mongodb-org

RUN mkdir -p /tmp/gtest && \
    cd /tmp/gtest && \
    git clone https://github.com/google/googletest gt && \
    cd gt && \
    git checkout release-1.8.0 && \
    cmake CMakeLists.txt && \
    make && make install && \
    cd / && rm -rf /tmp/gtest

RUN mkdir -p /tmp/mongocxx && cd /tmp/mongocxx && \
    \
    mkdir bson && cd bson && \
    wget -qO- https://github.com/mongodb/libbson/archive/1.9.5.tar.gz | tar zxvf - --strip-components=1 && \
    cmake . && \
    make && make install && \
    cd ../ && \
    \
    mkdir mongoc && cd mongoc && \
    wget -qO- https://github.com/mongodb/mongo-c-driver/archive/1.9.5.tar.gz | tar zxvf - --strip-components=1 && \
    rm -rf src/libbson && \
    mv ../bson src/libbson && \
    \
    cd src/zlib-1.2.11 && \
    cmake . && \
    make && make install && \
    cd ../ && \
    \
    cd ../ && \
    ./autogen.sh && \
    cmake -DCMAKE_BUILD_TYPE=Debug -DSASL_LIBS="" . && \
    make && make install && \
    cd ../ && \
    \
    git clone https://github.com/mongodb/mongo-cxx-driver drv -b releases/stable --depth=1 && \
    cd drv && \
    git checkout r3.2.0 && \
    CMAKE_PREFIX_PATH="/tmp/mongocxx/bson/build/cmake:/tmp/mongocxx/mongoc/src/zlib-1.2.11:/tmp/mongocxx/mongoc/src/mongoc" \
      cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local . && \
    make && make install && \
    cd / && rm -rf /tmp/mongocxx

ENV PYTHON_EXECUTABLE=/usr/bin/python \
    BOOST_ROOT=/usr/bin \
    GTEST_ROOT=/usr/bin \
    LIBBSONCXX_DIR=/usr/bin \
    LIBMONGOCXX_DIR=/usr/bin \
    ZeroMQ_DIR=/usr/bin \
    cppzmq_DIR=/usr/bin \
    ROCKSDB_ROOT_DIR=/usr/bin

RUN mkdir -p /tmp/catapult && \
    cd /tmp/catapult && \
    wget -qO- https://github.com/nemtech/catapult-server/archive/v0.1.0.1.tar.gz | tar xzvf - --strip-components=1 && \
    mkdir _build && cd _build && \
    cmake -DCMAKE_BUILD_TYPE=RelWithDebugInfo \
      -DCMAKE_CXX_FLAGS="-pthread" \
      -DPYTHON_EXECUTABLE=/usr/bin/python3 \
      -DBSONCXX_LIB=/usr/lib/libbsoncxx.so \
      -DMONGOCXX_LIB=/usr/lib/libmongocxx.so \
      .. && \
    make publish && make && \
    make install && \
    cd / && rm -rf /tmp/catapult
