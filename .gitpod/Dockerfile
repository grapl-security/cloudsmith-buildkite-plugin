FROM gitpod/workspace-full:commit-8fc141dbdd92030a435ead06617c6d37651d8312

USER gitpod

RUN npm install --global bash-language-server@2.0.0

COPY .bashrc.d/* /home/gitpod/.bashrc.d/
