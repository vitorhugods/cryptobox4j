FROM ubuntu:20.04

# disable prompts from the txdata
ENV DEBIAN_FRONTEND=noninteractive
# update dependencies in the base image
RUN apt-get update && apt-get upgrade -y
# install build tools
RUN apt-get install -qqy --no-install-recommends \
    	git \
    	wget \
    	build-essential \
    	gcc \
    	software-properties-common \
    	unzip \
    	clang \
    	vim \
    	pkg-config \
    	strace \
    	less \
    	g++-multilib \
    	libc6-dev-i386 \
    	sudo \
    	curl \
    	openjdk-8-jdk \
    	maven

# set correct java home for Java 8 and select it as correct java
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

# install rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# prepare final builds
WORKDIR /wire/cryptobox
COPY Makefile .

##### build Wire cryptobox
COPY mk ./mk
RUN make cryptobox

##### build native Cryptobox-Jni
RUN mkdir src
COPY src/cryptobox-jni.c ./src/
RUN make compile-native

##### build java wrapper around cryptobox
COPY src/main ./src/main
COPY src/test ./src/test
COPY pom.xml .
# set env, as it doesn't work by default inside the docker image
ENV LD_LIBRARY_PATH="/wire/cryptobox/build/lib"
# build rest of the java code
RUN mvn package -DargLine="-Djava.library.path=/wire/cryptobox/build/lib"

##### package everything to /wire/cryptobox/dist
RUN make dist
RUN echo "Libraries are ready in /wire/cryptobox/dist"
