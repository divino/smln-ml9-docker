FROM centos:centos7

# Please download the MarkLogic in their official site
# https://developer.marklogic.com/products

# I borrowed a lot from the following links (Thanks to the author.):
# https://github.com/corpbob/OpenShiftHowToGuides/blob/marklogic/marklogic/Dockerfile
# https://github.com/corpbob/s2i-slush-ml/blob/master/Dockerfile

ENV WORKING_DIR /var/opt/MarkLogic

ARG ML_RPM_FILE
ARG ML_VERSION
ARG ML_ADMIN_USER
ARG ML_ADMIN_PASSWORD

# Download ML rpm
ADD ${ML_RPM_FILE} /tmp/ml.rpm
ADD initialize-ml.sh /tmp/initialize-ml.sh

WORKDIR /${WORKING_DIR}

RUN chmod +x /tmp/initialize-ml.sh

# Install MarkLogic using Python
RUN yum -y install initscripts /tmp/ml.rpm python-setuptools 

# Expose MarkLogic admin
# 7997 = HealthCheck (HTTP)
# 8000 = App-Services (HTTP)
# 8001 = Admin (HTTP)
# 8002 = Manage (HTTP)
# 8050 = User Interface of the Slush MarkLogic Node Project
# Add other ports you want to expose here
EXPOSE 7997 7998 7999 8000 8001 8002 8005 8004 30050 30051 8040 8041 8070 8050

# Automate initialization of MarkLogic
RUN mkdir -p /var/opt/MarkLogic/Logs \ 
  && /sbin/service MarkLogic start \
  && /tmp/initialize-ml.sh -u ${ML_ADMIN_USER} -p ${ML_ADMIN_PASSWORD} 

RUN curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
RUN yum -y install git nodejs ruby unzip bzip2 java-1.8.0-openjdk wget \ 
  && curl https://developer.marklogic.com/download/binaries/mlcp/mlcp-9.0.1-bin.zip -o mlcp.zip \ 
  && unzip mlcp.zip \
  && mv mlcp-9.0.1 /usr/local/mlcp

# install slush marklogic node and dependencies
RUN npm install -g gulp && npm install -g slush && npm install -g bower
RUN mkdir -p /var/opt/ \
  && cd /var/opt/ \
  && git clone https://github.com/marklogic-community/slush-marklogic-node.git \
  && cd /var/opt/slush-marklogic-node/ \
  && npm install

# download phantomjs
RUN mkdir -p /opt/phantomjs \
  && cd /opt/phantomjs \
  && wget https://github.com/Medium/phantomjs/releases/download/v2.1.1//phantomjs-2.1.1-linux-x86_64.tar.bz2 

# install phantomjs
RUN cd /opt/phantomjs \
  && tar -xjvf phantomjs-2.1.1-linux-x86_64.tar.bz2 --strip-components 1 \
  && ln -s /opt/phantomjs/bin/phantomjs /usr/bin/phantomjs

# allow root to run bower
RUN echo '{ "allow_root": true }' > /root/.bowerrc

# generate default project
RUN cd /var/opt/slush-marklogic-node/ \
  && gulp --gulpfile=slushfile.js --app-name=slush-default --theme=default --ml-version=${ML_VERSION} --ml-host=localhost --ml-admin-user=${ML_ADMIN_USER} --ml-admin-pass=${ML_ADMIN_PASSWORD} ---ml-http-port=8040 --node-port=8050 --guest-access=true --disallow-updates=true --appusers-only=true

# install default project dependencies and build
RUN cd /var/opt/slush-marklogic-node/slush-default/ \
  && npm install \
  && gulp build \
  && /sbin/service MarkLogic restart \
  && ./ml local install local mlcp -options_file import-sample-data.options

# Clean up
RUN yum clean all && rm -rf /tmp/ml.rpm

# start marklogic
ENTRYPOINT /sbin/service MarkLogic start \
  && cd /var/opt/slush-marklogic-node/slush-default \
  && gulp serve-local --nosync > /tmp/slush-marklogic-node.log  


