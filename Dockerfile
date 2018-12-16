FROM postgres:alpine

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.cloud.tencent.com/' /etc/apk/repositories && sed -i 's/http:/https:/' /etc/apk/repositories

RUN set -ex \
  && apk add --no-cache --virtual .fetch-deps ca-certificates cmake git openssl tar \
  && git clone https://github.com/jaiminpan/pg_jieba \
  && apk add --no-cache --virtual .build-deps gcc g++ libc-dev make postgresql-dev \
  && apk add --no-cache --virtual .rundeps libstdc++ \
  && cd /pg_jieba \
  && git submodule update --init --recursive \
  && mkdir build \
  && cd build \
  && cmake .. \
  && make \
  && make install \
  && echo -e "  \n\
  # echo \"timezone = 'Asia/Shanghai'\" >> /var/lib/postgresql/data/postgresql.conf \n\
  echo \"shared_preload_libraries = 'pg_jieba.so'\" >> /var/lib/postgresql/data/postgresql.conf" \
  > /docker-entrypoint-initdb.d/init-dict.sh \
# The following command is not required if load database from backup
  && echo -e "CREATE EXTENSION pg_jieba;" > /docker-entrypoint-initdb.d/init-jieba.sql \
# RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
#   && echo "Asia/Shanghai" >  /etc/timezone
  && apk del .build-deps .fetch-deps \
  && rm -rf /usr/src/postgresql /pg_jieba \
  && find /usr/local -name '*.a' -delete
  
