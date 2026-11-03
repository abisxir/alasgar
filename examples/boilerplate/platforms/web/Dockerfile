FROM emscripten/emsdk:3.1.70 AS emcc_nim_base

RUN curl https://nim-lang.org/choosenim/init.sh -sSf -o /tmp/init.sh
RUN sh /tmp/init.sh -y
RUN ln -s /root/.nimble/bin/nim /usr/bin/nim
RUN ln -s /root/.nimble/bin/nimble /usr/bin/nimble

FROM emcc_nim_base

#COPY alasgar /alasgar
#RUN rm -rf alasgar/README.md
#WORKDIR /alasgar
#RUN nimble install -y

WORKDIR /app
COPY . /app
