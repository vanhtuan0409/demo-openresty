INSTALL_DIR="${CURDIR}/openresty"
OPENRESTY_VERSION=1.15.8.1
DOWNLOAD_DIR=/tmp/openresty

download:
	mkdir -p ${DOWNLOAD_DIR}
	wget -O ${DOWNLOAD_DIR}/source.tar.gz https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz
	tar -C ${DOWNLOAD_DIR} -xvzf ${DOWNLOAD_DIR}/source.tar.gz

.ONESHELL:
install:
	cd ${DOWNLOAD_DIR}/openresty-${OPENRESTY_VERSION}
	./configure -j2 --prefix=${INSTALL_DIR}
	make -j2
	make install

uninstall:
	rm -rf ${INSTALL_DIR}

start_nginx:
	./openresty/bin/openresty -p `pwd`/ -c conf/nginx.conf

stop_nginx:
	./openresty/bin/openresty -p `pwd`/ -s stop

reload_nginx:
	./openresty/bin/openresty -p `pwd`/ -s reload

check_nginx:
	./openresty/bin/openresty -p `pwd`/ -t
