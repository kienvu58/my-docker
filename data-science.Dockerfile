FROM ubuntu:20.04

ENV PATH=${PATH}:/conda/bin
ENV SHELL=/usr/bin/bash

ARG TINI_VERSION=v0.19.0

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y --fix-missing \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      apt-utils \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      curl \
      font-manager \
      graphviz \
      git \
      gcc \
      g++ \
      npm \
      screen \
      tzdata \
      zlib1g-dev \
      bash-completion \
      vim \
      openssh-server \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && curl https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -L -o /usr/bin/tini \
    && chmod +x /usr/bin/tini

ENV CONDA_ROOT=/conda

ARG CONDA_VERSION=4.12.0

RUN curl https://repo.anaconda.com/miniconda/Miniconda3-py39_${CONDA_VERSION}-Linux-x86_64.sh -k -o /miniconda.sh \
    && sh /miniconda.sh -b -p ${CONDA_ROOT} \
    && rm -f /miniconda.sh \
    && ${CONDA_ROOT}/bin/conda init bash 

COPY environment.yaml /

RUN ${CONDA_ROOT}/bin/conda env create -n ds -f /environment.yaml

COPY sshd_config /etc/ssh/
COPY entrypoint.sh /
RUN bash -c 'source ${CONDA_ROOT}/bin/activate ds' \
    && echo "conda activate ds\nexport LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu:${CONDA_ROOT}/envs/ds/lib/" >> ${HOME}/.bashrc \
    && ${CONDA_ROOT}/bin/conda clean -afy \
    && find ${CONDA_ROOT} -follow -type f -name '*.pyc' -delete \
    && find ${CONDA_ROOT} -follow -type f -name '*.js.map' -delete \
    && echo "#!/bin/bash\n\
      source /conda/bin/activate ds\n\
      jupyter-lab --allow-root --ip=0.0.0.0 --no-browser --NotebookApp.token='' --notebook-dir=/root" > /run-jupyter \
    && chmod 755 /run-jupyter \
    && chmod 755 /entrypoint.sh

WORKDIR /root
ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD ["/entrypoint.sh"]
