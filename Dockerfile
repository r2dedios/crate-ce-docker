####################
## STEP 1: Build  ##
####################
# Image Base
FROM centos:7 AS builder

# Git install
RUN yum install -y git

# Python 3.6 repository and packages
RUN yum install -y https://centos7.iuscommunity.org/ius-release.rpm
RUN yum install -y python36u python36u-libs python36u-devel python36u-pip

# JDK and JVM install
RUN yum install -y java-11-openjdk-headless java-11-openjdk-devel 
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.3.7-0.el7_6.x86_64
ENV PATH=$PATH:\$JAVA_HOME/bin

# CrateDB-CE Compilation
WORKDIR /tmp
RUN git clone https://github.com/crate/crate.git
WORKDIR /tmp/crate
RUN git submodule update --init
RUN git checkout 4.0.2
RUN ./gradlew clean communityEditionDistTar

# Copy Tar distribution file
RUN cp /tmp/crate/app/build/distributions/crate-ce-4.0.2-27add9a.tar.gz /tmp
WORKDIR /tmp
RUN tar xzf crate-ce-4.0.2-27add9a.tar.gz


####################
## STEP 2: Run    ##
####################
FROM centos:7

# Labels
LABEL maintainer="alex.ansi.c@gmail.com"
LABEL version="1.0"
LABEL description="CrateDB CE"
LABEL vendor="Alejandro Villegas"
LABEL image_name="cratedb_ce"

# JVM Install
RUN yum install -y java-11-openjdk-headless
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.3.7-0.el7_6.x86_64
ENV PATH=$PATH:\$JAVA_HOME/bin

# Run CrateDB-CE
ENV CRATE_HEAP_SIZE="2g"
RUN useradd crate
USER crate
COPY --from=builder --chown=crate:crate /tmp/crate-ce-* /crate-ce/

# Ports
EXPOSE 4200

# Entrypoint
ENTRYPOINT ["/crate-ce/bin/crate"]
