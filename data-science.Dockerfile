ARG DOCKER_REPO=nvcr.io/nvidia/cuda
ARG CUDA_VERSION=11.6.2
ARG OS_FLAVOR=devel-ubuntu20.04
FROM ${DOCKER_REPO}:${CUDA_VERSION}-${OS_FLAVOR}

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
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && curl https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -L -o /usr/bin/tini \
    && chmod +x /usr/bin/tini

ENV CONDA_ROOT=/conda
ENV NOTEBOOKS_DIR=/root

ARG CONDA_VERSION=4.12.0

RUN curl https://repo.anaconda.com/miniconda/Miniconda3-py39_${CONDA_VERSION}-Linux-x86_64.sh -k -o /miniconda.sh \
    && sh /miniconda.sh -b -p ${CONDA_ROOT} \
    && rm -f /miniconda.sh \
    && echo "conda ${CONDA_VERSION}" >> /conda/conda-meta/pinned \
    && ${CONDA_ROOT}/bin/conda init bash \
    && echo "#!/bin/bash\n\
      source /conda/bin/activate ds\n\
      jupyter-lab --allow-root --ip=0.0.0.0 --no-browser --NotebookApp.token='' --notebook-dir=${NOTEBOOKS_DIR}" > /run-jupyter \
    && chmod 755 /run-jupyter \
    && mkdir -p ${NOTEBOOKS_DIR}

RUN ${CONDA_ROOT}/bin/conda create -n ds python=3.9 \
    && echo "conda activate ds" >> ${HOME}/.bashrc \
    && bash -c 'source ${CONDA_ROOT}/bin/activate ds ; \
      conda install -c conda-forge nodejs==17.9.0 jupyterlab -y ; \
      jupyter labextension install -y --clean \
        @jupyter-widgets/jupyterlab-manager' \
    && ${CONDA_ROOT}/bin/conda clean -afy \
    && find ${CONDA_ROOT} -follow -type f -name '*.pyc' -delete \
    && find ${CONDA_ROOT} -follow -type f -name '*.js.map' -delete

EXPOSE 8888

WORKDIR ${NOTEBOOKS_DIR}
SHELL ["/bin/bash", "-c"]
ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD ["/run-jupyter" ]
