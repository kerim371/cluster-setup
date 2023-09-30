# ======================================================
# SET VARS
APP_DIR=$HOME/shared_app
SHARED_DIR=$HOME/shared
JL_DEPOT=$HOME/.julia
MASTER_NAME=master-fwi

GCC_MAJ="10"
GCC_MIN="2"
GCC_PATCH="0"
GCC_PREFIX=$APP_DIR/gcc/$GCC_MAJ.$GCC_MIN
GCC_ROOT=$GCC_PREFIX
CC=$GCC_ROOT/bin/gcc
CXX=$GCC_ROOT/bin/g++

PY_MAJ="3"
PY_MIN="9"
PY_PATCH="18"
PY_PREFIX="$APP_DIR/python/python-$PY_MAJ.$PY_MIN"
PY_ROOT=$PY_PREFIX

JL_MAJ="1"
JL_MIN="6"
JL_PATCH="7"
JL_PREFIX="$APP_DIR/julia"
JL_ROOT=$JL_PREFIX/julia-$JL_MAJ.$JL_MIN

# ======================================================
# ADD SERVICES AT STARTUP AND MOUNT SHARED DIRS
sudo systemctl enable rpcbind
sudo systemctl enable nfs-server
sudo systemctl start rpcbind
sudo systemctl start nfs-server

mkdir -p $APP_DIR
mkdir -p $SHARED_DIR
mkdir -p $JL_DEPOT

sudo mount -t nfs $MASTER_NAME:$APP_DIR $APP_DIR
sudo mount -t nfs $MASTER_NAME:$SHARED_DIR $SHARED_DIR
sudo mount -t nfs $MASTER_NAME:$JL_DEPOT $JL_DEPOT

grep -qxF ''$MASTER_NAME':'$APP_DIR' '$APP_DIR' nfs rw,sync,hard,intr 0 0' /etc/fstab || echo ''$MASTER_NAME':'$APP_DIR' '$APP_DIR' nfs rw,sync,hard,intr 0 0' >> /etc/fstab
grep -qxF ''$MASTER_NAME':'$SHARED_DIR' '$SHARED_DIR' nfs rw,sync,hard,intr 0 0' /etc/fstab || echo ''$MASTER_NAME':'$SHARED_DIR' '$SHARED_DIR' nfs rw,sync,hard,intr 0 0' >> /etc/fstab
grep -qxF ''$MASTER_NAME':'$JL_DEPOT' '$JL_DEPOT' nfs rw,sync,hard,intr 0 0' /etc/fstab || echo ''$MASTER_NAME':'$JL_DEPOT' '$JL_DEPOT' nfs rw,sync,hard,intr 0 0' >> /etc/fstab

# ======================================================
# MODIFY ~/.bashrc
export PATH=$PY_ROOT/bin:$PATH
export LD_LIBRARY_PATH=$PY_ROOT/lib:$LD_LIBRARY_PATH
export PYTHON=$PY_ROOT/bin/python

# modify ~/.bashrc
grep -qxF 'export CC='$CC $HOME/.bashrc || echo 'export CC='$CC >> $HOME/.bashrc
grep -qxF 'export CXX='$CXX $HOME/.bashrc || echo 'export CXX='$CXX >> $HOME/.bashrc
grep -qxF 'export PATH='$GCC_ROOT'/bin:$PATH' $HOME/.bashrc || echo 'export PATH='$GCC_ROOT'/bin:$PATH' >> $HOME/.bashrc
grep -qxF 'export LD_LIBRARY_PATH='$GCC_ROOT'/lib64:$LD_LIBRARY_PATH' $HOME/.bashrc || echo 'export LD_LIBRARY_PATH='$GCC_ROOT'/lib64:$LD_LIBRARY_PATH' >> $HOME/.bashrc
grep -qxF 'export PATH='$PY_ROOT'/bin:$PATH' $HOME/.bashrc || echo 'export PATH='$PY_ROOT'/bin:$PATH' >> $HOME/.bashrc
grep -qxF 'export LD_LIBRARY_PATH='$PY_ROOT'/lib:$LD_LIBRARY_PATH' $HOME/.bashrc || echo 'export LD_LIBRARY_PATH='$PY_ROOT'/lib:$LD_LIBRARY_PATH' >> $HOME/.bashrc
grep -qxF 'export PYTHON='$PY_ROOT'/bin/python' $HOME/.bashrc || echo 'export PYTHON='$PY_ROOT'/bin/python' >> $HOME/.bashrc

export PATH=$JL_ROOT/bin:$PATH
export JULIA=$JL_ROOT/bin/julia

# modify ~/.bashrc
grep -qxF 'export PATH='$JL_ROOT'/bin:$PATH' $HOME/.bashrc || echo 'export PATH='$JL_ROOT'/bin:$PATH' >> $HOME/.bashrc
