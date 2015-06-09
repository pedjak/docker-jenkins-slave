FROM ubuntu:14.04
MAINTAINER Luke Bunselmeyer <wmlukeb@gmail.com>

RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

COPY locale /etc/default/locale

#RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
RUN apt-get -qq update
RUN apt-get install -y build-essential python-software-properties software-properties-common wget curl git fontconfig docker.io

# SSH server
RUN apt-get install -y openssh-server
RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd

# Java 1.7
RUN wget --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u67-b01/jdk-7u67-linux-x64.tar.gz
RUN mkdir -p /opt/jdk
RUN tar -zxf jdk-7u67-linux-x64.tar.gz -C /opt/jdk

# Java 1.8
RUN wget --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u11-b12/jdk-8u11-linux-x64.tar.gz
RUN mkdir -p /opt/jdk
RUN tar -zxf jdk-8u11-linux-x64.tar.gz -C /opt/jdk

# Maven 3.0.5
RUN wget http://apache.petsads.us/maven/maven-3/3.0.5/binaries/apache-maven-3.0.5-bin.tar.gz
RUN mkdir -p /opt/maven
RUN tar -zxf apache-maven-3.0.5-bin.tar.gz -C /opt/maven
RUN ln -s /opt/maven/apache-maven-3.0.5/bin/mvn /usr/bin

# Set the default java version to 1.7
RUN update-alternatives --install /usr/bin/java java /opt/jdk/jdk1.7.0_67/bin/java 100
RUN update-alternatives --install /usr/bin/javac javac /opt/jdk/jdk1.7.0_67/bin/javac 100

# Set Java and Maven env variables
ENV M2_HOME /opt/maven/apache-maven-3.0.5
ENV JAVA_HOME /opt/jdk/jdk1.7.0_67
#ENV JAVA_OPTS -Xmx2G -Xms2G -XX:PermSize=256M -XX:MaxPermSize=256m

# Load scripts
COPY bootstrap bootstrap
RUN chmod +x -Rv bootstrap

USER root

# Add user jenkins to the image
RUN adduser --quiet jenkins
RUN adduser jenkins sudo
RUN echo "jenkins:jenkins" | chpasswd

# Adjust perms for jenkins user
#RUN chown -R jenkins /opt/nvm
RUN echo "JDK7_HOME=\"/opt/jdk/jdk1.7.0_67\"" >> /etc/environment
RUN echo "JDK8_HOME=\"/opt/jdk/jdk1.8.0_11\"" >> /etc/environment
#RUN echo "source /opt/nvm/nvm.sh" >> /home/jenkins/.profile
RUN chown jenkins /home/jenkins/.profile

# Standard SSH port
EXPOSE 22
RUN sed -i 's|PermitRootLogin without-password|PermitRootLogin yes|g' /etc/ssh/sshd_config

#NFS
RUN apt-get install -y nfs-common portmap

RUN apt-get install -y parallel

# Startup services when running the container
CMD ["./bootstrap/init.sh"]
