TERMUX_PKG_HOMEPAGE=https://openethereum.github.io
TERMUX_PKG_DESCRIPTION="Lightweight Ethereum Client"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=3.1.0
TERMUX_PKG_SRCURL=https://github.com/openethereum/openethereum/archive/v${TERMUX_PKG_VERSION}.zip
TERMUX_PKG_SHA256=62e577abbeddaeb38071e396847a4fcaa4117709aa2689f0d53005bd4c7d7690
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_configure() {
	termux_setup_cmake

	CXXFLAGS+=" --target=$CCTERMUX_HOST_PLATFORM"
	CFLAGS+=" --target=$CCTERMUX_HOST_PLATFORM"
	if [ $TERMUX_ARCH = "arm" ]; then
		CFLAGS="${CFLAGS/-mthumb/}"
		CMAKE_SYSTEM_PROCESSOR="armv7-a"
	else
		CMAKE_SYSTEM_PROCESSOR=$TERMUX_ARCH
	fi

	cat <<- EOF > $TERMUX_COMMON_CACHEDIR/defaultcache.cmake
		CMAKE_CROSSCOMPILING=ON
		CMAKE_LINKER="$TERMUX_STANDALONE_TOOLCHAIN/bin/$LD $LDFLAGS"
		CMAKE_SYSTEM_NAME=Android
		CMAKE_SYSTEM_VERSION=$TERMUX_PKG_API_LEVEL
		CMAKE_SYSTEM_PROCESSOR=$CMAKE_SYSTEM_PROCESSOR
		CMAKE_ANDROID_STANDALONE_TOOLCHAIN=$TERMUX_STANDALONE_TOOLCHAIN

		CMAKE_AR="$(command -v $AR)"
		CMAKE_UNAME="$(command -v uname)"
		CMAKE_RANLIB="$(command -v $RANLIB)"
		CMAKE_C_FLAGS="$CFLAGS -Wno-error=shadow $CPPFLAGS"
		CMAKE_CXX_FLAGS="$CXXFLAGS $CPPFLAGS"
		CMAKE_FIND_ROOT_PATH=$TERMUX_PREFIX
		CMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER
		CMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY
		CMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY
		CMAKE_SKIP_INSTALL_RPATH=ON
		CMAKE_USE_SYSTEM_LIBRARIES=ON
		BUILD_TESTING=OFF

		WITH_GFLAGS=OFF
	EOF

	export CMAKE=$TERMUX_PKG_BUILDER_DIR/cmake_mod.sh
	export TERMUX_COMMON_CACHEDIR

	termux_setup_rust
	cargo clean
	export NDK_HOME=$NDK
	RUSTFLAGS+=" -C link-args=-lc++"
}

termux_step_make() {
	cargo build --jobs $TERMUX_MAKE_PROCESSES --target $CARGO_TARGET_NAME --release --features final
	for prog in evmbin ethstore-cli ethkey-cli; do
		cargo build --jobs $TERMUX_MAKE_PROCESSES --target $CARGO_TARGET_NAME --release -p $prog
	done
}

termux_step_make_install() {
	install -Dm755 -t $TERMUX_PREFIX/bin target/${CARGO_TARGET_NAME}/release/openethereum
	install -Dm755 -t $TERMUX_PREFIX/bin target/${CARGO_TARGET_NAME}/release/openethereum-evm
	install -Dm755 -t $TERMUX_PREFIX/bin target/${CARGO_TARGET_NAME}/release/ethstore
	install -Dm755 -t $TERMUX_PREFIX/bin target/${CARGO_TARGET_NAME}/release/ethkey
}
