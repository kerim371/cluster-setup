# ======================================================
# SET VARS
# make shared folders for app and general purpose
APP_DIR=$HOME/shared_app
SHARED_DIR=$HOME/shared
JL_DEPOT=$HOME/.julia

# Build newer GCC as default GCC-4.8.5 is too old to support OmpenMP
# It preferably to have GCC > 9
GCC_MAJ="10"
GCC_MIN="2"
GCC_PATCH="0"
GCC_PREFIX=$APP_DIR/gcc/$GCC_MAJ.$GCC_MIN
GCC_ROOT=$GCC_PREFIX

# CentOS 7 comes with OpenSSL version 1.0.2 (`openssl version` command)
# Currently Python versions 3.6 to 3.9 are compatible with OpenSSL 1.0.2, 1.1.0, and 1.1.1. 
# For the most part Python also works with LibreSSL >= 2.7.1 with some missing features and broken tests.
PY_MAJ="3"
PY_MIN="9"
PY_PATCH="18"
PY_PREFIX="$APP_DIR/python/python-$PY_MAJ.$PY_MIN"
PY_ROOT=$PY_PREFIX
PY_PACKAGES="numpy pandas h5py scipy matplotlib jill"   # devito and pyrevolve will be installed by JUDI itself during 'Pkg.build("JUDI")`

JL_MAJ="1"
JL_MIN="6"
JL_PATCH="7"
JL_PREFIX="$APP_DIR/julia"
JL_ROOT=$JL_PREFIX/julia-$JL_MAJ.$JL_MIN

# ======================================================
# MAKE SHARED FOLDERS (run service and add it to startup (requires nfs-utils package))
sudo systemctl enable rpcbind
sudo systemctl enable nfs-server
sudo systemctl start rpcbind
sudo systemctl start nfs-server

# share python, julia and ~/shared folders
mkdir -p $APP_DIR
mkdir -p $SHARED_DIR
mkdir -p $JL_DEPOT

sudo chmod -R 777 $APP_DIR
sudo chmod -R 777 $SHARED_DIR
sudo chmod -R 777 $JL_DEPOT

# `sudo -i` seems doesn't work with `scl` installed and enabled
# that is why here we have `sudo` at the end of the command
grep -qxF ''$APP_DIR' *(rw,sync,no_root_squash,no_subtree_check)' /etc/exports || echo ''$APP_DIR' *(rw,sync,no_root_squash,no_subtree_check)' | sudo tee -a /etc/exports
grep -qxF ''$SHARED_DIR' *(rw,sync,no_root_squash,no_subtree_check)' /etc/exports || echo ''$SHARED_DIR' *(rw,sync,no_root_squash,no_subtree_check)' | sudo tee -a /etc/exports
grep -qxF ''$JL_DEPOT' *(rw,sync,no_root_squash,no_subtree_check)' /etc/exports || echo ''$JL_DEPOT' *(rw,sync,no_root_squash,no_subtree_check)' | sudo tee -a /etc/exports

sudo exportfs -a
sudo systemctl restart nfs

# ======================================================
# INSTALL GCC FROM SOURCE
wget https://ftp.gnu.org/gnu/gcc/gcc-$GCC_MAJ.$GCC_MIN.$GCC_PATCH/gcc-$GCC_MAJ.$GCC_MIN.$GCC_PATCH.tar.xz
tar xf gcc-$GCC_MAJ.$GCC_MIN.$GCC_PATCH.tar.xz

mkdir -p gcc-build
cd gcc-build
../gcc-$GCC_MAJ.$GCC_MIN.$GCC_PATCH/configure --enable-languages=c --disable-multilib --prefix=$GCC_PREFIX
make  # PARALLEL BUILD WITH DEFAULT GCC 4.8.5 DOESN'T WORK HERE! SO DON'T PASS `-j` FLAG
make install

# remove unnesessary files/dirs
cd ..
rm gcc-$GCC_MAJ.$GCC_MIN.$GCC_PATCH.tar.xz
rm -f -r gcc-$GCC_MAJ.$GCC_MIN.$GCC_PATCH
rm -f -r gcc-build

ln -sf $GCC_ROOT/bin/gcc $GCC_ROOT/bin/gcc-10

# run CMake with gcc-11 by default
export CC=$GCC_ROOT/bin/gcc
export CXX=$GCC_ROOT/bin/g++
# add GCC11 and GCC12 GLIBCXX_... to be able to compile and link with those compilers
export LD_LIBRARY_PATH=$GCC_ROOT/lib64:$LD_LIBRARY_PATH

# modify ~/.bashrc
grep -qxF 'export CC='$CC $HOME/.bashrc || echo 'export CC='$CC >> $HOME/.bashrc
grep -qxF 'export CXX='$CXX $HOME/.bashrc || echo 'export CXX='$CXX >> $HOME/.bashrc
grep -qxF 'export PATH='$GCC_ROOT'/bin:$PATH' $HOME/.bashrc || echo 'export PATH='$GCC_ROOT'/bin:$PATH' >> $HOME/.bashrc
grep -qxF 'export LD_LIBRARY_PATH='$GCC_ROOT'/lib64:$LD_LIBRARY_PATH' $HOME/.bashrc || echo 'export LD_LIBRARY_PATH='$GCC_ROOT'/lib64:$LD_LIBRARY_PATH' >> $HOME/.bashrc

# ======================================================
# INSTALL PYTHON FROM SOURCES
wget https://www.python.org/ftp/python/$PY_MAJ.$PY_MIN.$PY_PATCH/Python-$PY_MAJ.$PY_MIN.$PY_PATCH.tgz
tar -xzf Python-$PY_MAJ.$PY_MIN.$PY_PATCH.tgz

# `--enable-optimizations` causes compilation error. Don't use it
cd Python-$PY_MAJ.$PY_MIN.$PY_PATCH/
./configure --with-lt --with-computed-gotos --with-system-ffi --enable-shared --with-ensurepip=install --prefix=$PY_PREFIX
make -j
make install

# remove unnesessary files/dirs
cd ..
rm Python-$PY_MAJ.$PY_MIN.$PY_PATCH.tgz
rm -f -r Python-$PY_MAJ.$PY_MIN.$PY_PATCH

ln -sf $PY_ROOT/bin/python$PY_MAJ $PY_ROOT/bin/python
ln -sf $PY_ROOT/bin/pip$PY_MAJ $PY_ROOT/bin/pip

export PATH=$PY_ROOT/bin:$PATH
export LD_LIBRARY_PATH=$PY_ROOT/lib:$LD_LIBRARY_PATH
export PYTHON=$PY_ROOT/bin/python

# modify ~/.bashrc
grep -qxF 'export PATH='$PY_ROOT'/bin:$PATH' $HOME/.bashrc || echo 'export PATH='$PY_ROOT'/bin:$PATH' >> $HOME/.bashrc
grep -qxF 'export LD_LIBRARY_PATH='$PY_ROOT'/lib:$LD_LIBRARY_PATH' $HOME/.bashrc || echo 'export LD_LIBRARY_PATH='$PY_ROOT'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
grep -qxF 'export PYTHON='$PY_ROOT'/bin/python' $HOME/.bashrc || echo 'export PYTHON='$PY_ROOT'/bin/python' >> $HOME/.bashrc

# reinstall urllib3 (needed by jill) to be compatible with current OpenSSL 1.0.2
$PYTHON -m pip uninstall urllib3 -y
$PYTHON -m pip install 'urllib3<2.0' 
$PYTHON -m pip install $PY_PACKAGES

# ======================================================
# INSTALL JULIA
$PYTHON -m jill install $JL_MAJ.$JL_MIN.$JL_PATCH --confirm --install_dir $JL_PREFIX --skip-symlinks

export PATH=$JL_ROOT/bin:$PATH
export JULIA=$JL_ROOT/bin/julia

# modify ~/.bashrc
grep -qxF 'export PATH='$JL_ROOT'/bin:$PATH' $HOME/.bashrc || echo 'export PATH='$JL_ROOT'/bin:$PATH' >> $HOME/.bashrc

$JULIA -e 'using Pkg;rm(abspath(first(DEPOT_PATH), "conda", "deps.jl"), force=true);rm(abspath(first(DEPOT_PATH), "packages", "Conda"), force=true, recursive=true);Pkg.add("PyCall");Pkg.build("PyCall")'
$JULIA -e 'using Pkg;Pkg.add("JUDI");Pkg.build("JUDI")' # JUDI will install devito and pyrevolve of desired versions
$JULIA -e 'using Pkg;Pkg.add.(["Statistics","Random","LinearAlgebra","Interpolations","DelimitedFiles","Distributed","SlimOptim","NLopt","HDF5","SegyIO","Plots","PyPlot","ImageFiltering","SetIntersectionProjection","ClusterManagers","ArgParse"])'

# make shared folders (run service and add it to startup (requires nfs-utils package))
sudo systemctl enable rpcbind
sudo systemctl enable nfs-server
sudo systemctl start rpcbind
sudo systemctl start nfs-server
