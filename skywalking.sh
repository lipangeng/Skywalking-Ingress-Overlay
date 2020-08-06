#!/bin/bash

# Copyright 2015 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -o errexit
set -o nounset
set -o pipefail
set -eux

export NGINX_VERSION=1.13.9
export NDK_VERSION=0.3.0
export VTS_VERSION=0.1.15
export SETMISC_VERSION=0.31
export STICKY_SESSIONS_VERSION=08a395c66e42
export MORE_HEADERS_VERSION=0.33
export NGINX_DIGEST_AUTH=274490cec649e7300fea97fed13d84e596bbc0ce
export NGINX_SUBSTITUTIONS=bc58cb11844bc42735bbaef7085ea86ace46d05b
export NGINX_OPENTRACING_VERSION=0.2.1
export OPENTRACING_CPP_VERSION=1.2.0
export ZIPKIN_CPP_VERSION=0.2.0
export JAEGER_VERSION=0.1.0
export MODSECURITY_VERSION=1.0.0
export LUA_VERSION=0.10.12rc2
export COOKIE_FLAG_VERSION=1.1.0

export BUILD_PATH=/tmp/build

export LUA_NGX_VERSION=0.10.15
export LUAJIT_VERSION=33b5f86c1b9ab53ad09c33f9097df42403587bea
export LUA_RESTY_CORE=0.1.17
export RESTY_LUAROCKS_VERSION=3.1.3
export LUA_STREAM_NGX_VERSION=0.0.7
export LUA_CJSON_VERSION=2.1.0.7

ARCH=$(uname -m)

get_src()
{
  hash="$1"
  url="$2"
  f=$(basename "$url")

  curl -sSL "$url" -o "$f"
  echo "$hash  $f" | sha256sum -c - || exit 10
  tar xzf "$f"
  rm -rf "$f"
}

if [[ ${ARCH} == "ppc64le" ]]; then
  clean-install software-properties-common
fi

apt-get update && apt-get dist-upgrade -y

rm -rf /usr/lib/liblua.so

apt-get remove -y --purge \
  lua5.1 liblua5.1-0 liblua5.1-dev

# install required packages to build
clean-install \
  bash \
  build-essential \
  curl ca-certificates \
  libgeoip1 \
  libgeoip-dev \
  patch \
  libpcre3 \
  libpcre3-dev \
  libssl-dev \
  zlib1g \
  zlib1g-dev \
  libaio1 \
  libaio-dev \
  openssl \
  libperl-dev \
  cmake \
  util-linux \
  lmdb-utils \
  libjemalloc1 libjemalloc-dev \
  wget \
  libcurl4-openssl-dev \
  procps \
  unzip \
  git g++ pkgconf flex bison doxygen libyajl-dev liblmdb-dev libtool dh-autoreconf libxml2 libpcre++-dev libxml2-dev \
  || exit 1

if [[ ${ARCH} == "s390x" ]]; then
  # avoid error:
  # git: ../nptl/pthread_mutex_lock.c:81: __pthread_mutex_lock: Assertion `mutex->__data.__owner == 0' failed.
  git config --global pack.threads "1"
fi

mkdir --verbose -p "$BUILD_PATH"
cd "$BUILD_PATH"

# download, verify and extract the source files
get_src 5faea18857516fe68d30be39c3032bd22ed9cf85e1a6fdf32e3721d96ff7fa42 \
        "http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz"

get_src 88e05a99a8a7419066f5ae75966fb1efc409bad4522d14986da074554ae61619 \
        "https://github.com/simpl/ngx_devel_kit/archive/v$NDK_VERSION.tar.gz"

get_src 97946a68937b50ab8637e1a90a13198fe376d801dc3e7447052e43c28e9ee7de \
        "https://github.com/openresty/set-misc-nginx-module/archive/v$SETMISC_VERSION.tar.gz"

get_src 5112a054b1b1edb4c0042a9a840ef45f22abb3c05c68174e28ebf483164fb7e1 \
        "https://github.com/vozlt/nginx-module-vts/archive/v$VTS_VERSION.tar.gz"

get_src a3dcbab117a9c103bc1ea5200fc00a7b7d2af97ff7fd525f16f8ac2632e30fbf \
        "https://github.com/openresty/headers-more-nginx-module/archive/v$MORE_HEADERS_VERSION.tar.gz"

get_src 53e440737ed1aff1f09fae150219a45f16add0c8d6e84546cb7d80f73ebffd90 \
        "https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng/get/$STICKY_SESSIONS_VERSION.tar.gz"

get_src ede0ad490cb9dd69da348bdea2a60a4c45284c9777b2f13fa48394b6b8e7671c \
        "https://github.com/atomx/nginx-http-auth-digest/archive/$NGINX_DIGEST_AUTH.tar.gz"

get_src 618551948ab14cac51d6e4ad00452312c7b09938f59ebff4f93875013be31f2d \
        "https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/$NGINX_SUBSTITUTIONS.tar.gz"

get_src ce66acf943a604ef9a0bb477c7efca1fe583076991647aa646aa3d8804328364 \
        "https://github.com/opentracing-contrib/nginx-opentracing/archive/v$NGINX_OPENTRACING_VERSION.tar.gz"

get_src c77041cb2f147ac81b2b0702abfced5565a9cebc318d045c060a4c3e074009ee \
        "https://github.com/opentracing/opentracing-cpp/archive/v$OPENTRACING_CPP_VERSION.tar.gz"

get_src 611eb6a1ff1c326c472421ae2486ba34a94ddc78d90047df3f097bcdad3298e3 \
        "https://github.com/rnburn/zipkin-cpp-opentracing/archive/v$ZIPKIN_CPP_VERSION.tar.gz"

get_src dab677f9a7a5eb1d7ecbd9e7c5af75613582b25fb0c587aa80130256989b7a6e \
        "https://github.com/SpiderLabs/ModSecurity-nginx/archive/v$MODSECURITY_VERSION.tar.gz"

get_src a3ba464326ae1fb87437c1a2d07d22970b99d627168b6bb965d8f9c1c7fddb12 \
        "https://github.com/jaegertracing/cpp-client/archive/v$JAEGER_VERSION.tar.gz"

get_src 9915ad1cf0734cc5b357b0d9ea92fec94764b4bf22f4dce185cbd65feda30ec1 \
        "https://github.com/AirisX/nginx_cookie_flag_module/archive/v$COOKIE_FLAG_VERSION.tar.gz"

get_src 7d5f3439c8df56046d0564b5857fd8a30296ab1bd6df0f048aed7afb56a0a4c2 \
        "https://github.com/openresty/lua-nginx-module/archive/v$LUA_NGX_VERSION.tar.gz"

get_src 3b43917a155b81b7d20fdbb3c1be4419626286616195ad426bff1f2f59aa3659 \
        "https://github.com/openresty/luajit2/archive/$LUAJIT_VERSION.tar.gz"

get_src 8f5f76d2689a3f6b0782f0a009c56a65e4c7a4382be86422c9b3549fe95b0dc4 \
        "https://github.com/openresty/lua-resty-core/archive/v$LUA_RESTY_CORE.tar.gz"

get_src c573435f495aac159e34eaa0a3847172a2298eb6295fcdc35d565f9f9b990513 \
        "https://luarocks.github.io/luarocks/releases/luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz"

get_src 99c47c75c159795c9faf76bbb9fa58e5a50b75286c86565ffcec8514b1c74bf9 \
        "https://github.com/openresty/stream-lua-nginx-module/archive/v$LUA_STREAM_NGX_VERSION.tar.gz"

get_src 59d2f18ecadba48be61061004c8664eaed1111a3372cd2567cb24c5a47eb41fe \
        "https://github.com/openresty/lua-cjson/archive/$LUA_CJSON_VERSION.tar.gz"

#https://blog.cloudflare.com/optimizing-tls-over-tcp-to-reduce-latency/
curl -sSL -o nginx__dynamic_tls_records.patch https://raw.githubusercontent.com/cloudflare/sslconfig/master/patches/nginx__1.11.5_dynamic_tls_records.patch

export MAKEFLAGS=-j$(($(grep -c ^processor /proc/cpuinfo) - 0))

# build opentracing lib
cd "$BUILD_PATH/opentracing-cpp-$OPENTRACING_CPP_VERSION"
mkdir .build
cd .build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF ..
make
make install

# build zipkin lib
cd "$BUILD_PATH/jaeger-client-cpp-$JAEGER_VERSION"
sed -i 's/-Werror//' CMakeLists.txt
mkdir .build
cd .build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=1 -DBUILD_TESTING=OFF -DJAEGERTRACING_WITH_YAML_CPP=OFF ..
make
make install

export HUNTER_INSTALL_DIR=$(cat _3rdParty/Hunter/install-root-dir)

# build zipkin lib
cd "$BUILD_PATH/zipkin-cpp-opentracing-$ZIPKIN_CPP_VERSION"
mkdir .build
cd .build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=1 -DBUILD_TESTING=OFF ..
make
make install

# Get Brotli source and deps
cd "$BUILD_PATH"
git clone --depth=1 https://github.com/google/ngx_brotli.git
cd ngx_brotli
git submodule init
git submodule update

# build modsecurity library
cd "$BUILD_PATH"
git clone -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
cd ModSecurity/
git checkout 4e6e4243a899ff46dccd189693b2f5d9421dcd98
git submodule init
git submodule update
sh build.sh
./configure --disable-doxygen-doc --disable-examples --disable-dependency-tracking
make
make install

# Install luajit from openresty fork
export LUAJIT_LIB=/usr/local/share
export LUA_LIB_DIR="$LUAJIT_LIB/lua/5.1"
export LUAJIT_INC=/usr/local/include/luajit-2.1

cd "$BUILD_PATH/luajit2-$LUAJIT_VERSION"
make CCDEBUG=-g
make install
export LUA_INCLUDE_DIR=/usr/local/include/luajit-2.1
ln -s $LUA_INCLUDE_DIR /usr/include/lua5.1

cd "$BUILD_PATH/luarocks-${RESTY_LUAROCKS_VERSION}"
./configure \
  --lua-suffix=jit-2.1.0-beta3 \
  --with-lua-include=/usr/local/include/luajit-2.1

make
make install

cd "$BUILD_PATH/lua-resty-core-$LUA_RESTY_CORE"
make install

if [[ ${ARCH} != "armv7l" ]]; then
  luarocks install lrexlib-pcre 2.7.2-1
fi

cd "$BUILD_PATH/lua-cjson-$LUA_CJSON_VERSION"
make all
make install

luarocks --verbose install lua-resty-lrucache 0.09-2
luarocks --verbose install lua-resty-http

cd "$BUILD_PATH"

# build nginx
cd "$BUILD_PATH/nginx-$NGINX_VERSION"

echo "Applying nginx patches..."
patch -p1 < $BUILD_PATH/nginx__dynamic_tls_records.patch

WITH_FLAGS="--with-debug \
  --with-pcre-jit \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_realip_module \
  --with-http_auth_request_module \
  --with-http_addition_module \
  --with-http_dav_module \
  --with-http_geoip_module \
  --with-http_gzip_static_module \
  --with-http_sub_module \
  --with-http_v2_module \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-threads \
  --with-http_secure_link_module"

if [[ ${ARCH} != "armv7l" || ${ARCH} != "aarch64" ]]; then
  WITH_FLAGS+=" --with-file-aio"
fi

CC_OPT="-g -O3 -flto -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -Wno-deprecated-declarations --param=ssp-buffer-size=4 -DTCP_FASTOPEN=23 -Wno-error=strict-aliasing -fPIC -I$HUNTER_INSTALL_DIR/include"
LD_OPT="-ljemalloc -Wl,-Bsymbolic-functions -fPIE -fPIC -pie -Wl,-z,relro -Wl,-z,now -L$HUNTER_INSTALL_DIR/lib"
   
if [[ ${ARCH} == "x86_64" ]]; then
  CC_OPT+=' -m64 -mtune=generic'
fi

WITH_MODULES="--add-module=$BUILD_PATH/ngx_devel_kit-$NDK_VERSION \
  --add-module=$BUILD_PATH/set-misc-nginx-module-$SETMISC_VERSION \
  --add-module=$BUILD_PATH/nginx-module-vts-$VTS_VERSION \
  --add-module=$BUILD_PATH/headers-more-nginx-module-$MORE_HEADERS_VERSION \
  --add-module=$BUILD_PATH/nginx-goodies-nginx-sticky-module-ng-$STICKY_SESSIONS_VERSION \
  --add-module=$BUILD_PATH/nginx-http-auth-digest-$NGINX_DIGEST_AUTH \
  --add-module=$BUILD_PATH/ngx_http_substitutions_filter_module-$NGINX_SUBSTITUTIONS \
  --add-module=$BUILD_PATH/nginx_cookie_flag_module-$COOKIE_FLAG_VERSION \
  --add-module=$BUILD_PATH/lua-nginx-module-$LUA_NGX_VERSION \
  --add-module=$BUILD_PATH/stream-lua-nginx-module-$LUA_STREAM_NGX_VERSION \
  --add-dynamic-module=$BUILD_PATH/nginx-opentracing-$NGINX_OPENTRACING_VERSION/opentracing \
  --add-dynamic-module=$BUILD_PATH/nginx-opentracing-$NGINX_OPENTRACING_VERSION/jaeger \
  --add-dynamic-module=$BUILD_PATH/nginx-opentracing-$NGINX_OPENTRACING_VERSION/zipkin \
  --add-dynamic-module=$BUILD_PATH/ModSecurity-nginx-$MODSECURITY_VERSION \
  --add-module=$BUILD_PATH/ngx_brotli"

./configure \
  --prefix=/usr/share/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --modules-path=/etc/nginx/modules \
  --http-log-path=/var/log/nginx/access.log \
  --error-log-path=/var/log/nginx/error.log \
  --lock-path=/var/lock/nginx.lock \
  --pid-path=/run/nginx.pid \
  --http-client-body-temp-path=/var/lib/nginx/body \
  --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
  --http-proxy-temp-path=/var/lib/nginx/proxy \
  --http-scgi-temp-path=/var/lib/nginx/scgi \
  --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
  ${WITH_FLAGS} \
  --without-mail_pop3_module \
  --without-mail_smtp_module \
  --without-mail_imap_module \
  --without-http_uwsgi_module \
  --without-http_scgi_module \
  --with-cc-opt="${CC_OPT}" \
  --with-ld-opt="${LD_OPT}" \
  ${WITH_MODULES} \
  && make || exit 1 \
  && make install || exit 1

echo "Cleaning..."

cd /

apt-mark unmarkauto \
  bash \
  curl ca-certificates \
  libgeoip1 \
  libpcre3 \
  zlib1g \
  libaio1 \
  xz-utils \
  geoip-bin \
  libyajl2 liblmdb0 libxml2 libpcre++ \
  gzip \
  openssl

apt-get remove -y --purge \
  build-essential \
  gcc-6 \
  cpp-6 \
  libgeoip-dev \
  libpcre3-dev \
  libssl-dev \
  zlib1g-dev \
  libaio-dev \
  linux-libc-dev \
  cmake \
  wget \
  unzip \
  git g++ pkgconf flex bison doxygen libyajl-dev liblmdb-dev libgeoip-dev libtool dh-autoreconf libpcre++-dev libxml2-dev

apt-get autoremove -y

mv /usr/share/nginx/sbin/nginx /usr/sbin

rm -rf "$BUILD_PATH"
rm -Rf /usr/share/man /usr/share/doc
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/apt/archives/*
rm -rf /usr/local/modsecurity/bin
rm -rf /usr/local/modsecurity/include
rm -rf /usr/local/modsecurity/lib/libmodsecurity.a

rm -rf $HOME/.hunter
