# ======================================================
# INSTALL BASIC PACKAGES (GCC comes along with CentOS 7)
sudo yum check-update
sudo yum install net-tools htop openmpi-devel nfs-utils nano wget git -y
sudo yum groupinstall 'Development Tools' # needed by `pyrevolve` (`devito` project)

# ======================================================
# INSTALL PYTHON FROM SOURCES
# CentOS 7 comes with OpenSSL version 1.0.2 (`openssl version` command)
# Currently Python versions 3.6 to 3.9 are compatible with OpenSSL 1.0.2, 1.1.0, and 1.1.1. 
# For the most part Python also works with LibreSSL >= 2.7.1 with some missing features and broken tests.
PY_MAJ="3"
PY_MIN="9"
PY_PATCH="18"
PY_PREFIX="/home/$USER/python/python-$PY_MAJ.$PY_MIN"
PY_PACKAGES="numpy pandas h5py scipy matplotlib jill"   # devito and pyrevolve will be installed by JUDI itself during 'Pkg.build("JUDI")`

sudo yum install gcc openssl-devel bzip2-devel libffi-devel -y
wget https://www.python.org/ftp/python/$PY_MAJ.$PY_MIN.$PY_PATCH/Python-$PY_MAJ.$PY_MIN.$PY_PATCH.tgz
tar -xzf Python-$PY_MAJ.$PY_MIN.$PY_PATCH.tgz

cd Python-$PY_MAJ.$PY_MIN.$PY_PATCH/
./configure --enable-optimizations --with-lt --with-computed-gotos --with-system-ffi --enable-shared --with-ensurepip=install --prefix=$PY_PREFIX
make
make install

# remove unnesessary files/dirs
rm Python-$PY_MAJ.$PY_MIN.$PY_PATCH.tgz
rm -f -r Python-$PY_MAJ.$PY_MIN.$PY_PATCH

ln -sf $PY_PREFIX/bin/python$PY_MAJ $PY_PREFIX/bin/python
ln -sf $PY_PREFIX/bin/pip$PY_MAJ $PY_PREFIX/bin/pip

export PATH=$PY_PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$PY_PREFIX/lib:$LD_LIBRARY_PATH
export PYTHON=$PY_PREFIX/bin/python

# modify ~/.bashrc
grep -qxF 'export PATH='$PY_PREFIX'/bin:$PATH' /home/$USER/.bashrc || echo 'export PATH='$PY_PREFIX'/bin:$PATH' >> /home/$USER/.bashrc
grep -qxF 'export LD_LIBRARY_PATH='$PY_PREFIX'/lib:$LD_LIBRARY_PATH' /home/$USER/.bashrc || echo 'export LD_LIBRARY_PATH='$PY_PREFIX'/lib:$LD_LIBRARY_PATH' >> /home/$USER/.bashrc
grep -qxF 'export PYTHON='$PY_PREFIX'/bin/python' /home/$USER/.bashrc || echo 'export PYTHON='$PY_PREFIX'/bin/python' >> /home/$USER/.bashrc

# reinstall urllib3 (needed by jill) to be compatible with current OpenSSL 1.0.2
$PYTHON -m pip uninstall urllib3 -y
$PYTHON -m pip install 'urllib3<2.0' 
$PYTHON -m pip install $PY_PACKAGES

# ======================================================
# INSTALL JULIA
JL_MAJ="1"
JL_MIN="6"
JL_PATCH="7"
JL_PREFIX="/home/$USER/julia"

$PYTHON -m jill install $JL_MAJ.$JL_MIN.$JL_PATCH --confirm --install_dir $JL_PREFIX --skip-symlinks

export PATH=$JL_PREFIX/julia-$JL_MAJ.$JL_MIN/bin:$PATH
export JULIA=$JL_PREFIX/julia-$JL_MAJ.$JL_MIN/bin/julia

# modify ~/.bashrc
grep -qxF 'export PATH='$JL_PREFIX/julia-$JL_MAJ.$JL_MIN'/bin:$PATH' /home/$USER/.bashrc || echo 'export PATH='$JL_PREFIX/julia-$JL_MAJ.$JL_MIN'/bin:$PATH' >> /home/$USER/.bashrc

$JULIA -e 'using Pkg;rm(abspath(first(DEPOT_PATH), "conda", "deps.jl"), force=true);rm(abspath(first(DEPOT_PATH), "packages", "Conda"), force=true, recursive=true);Pkg.add("PyCall");Pkg.build("PyCall")'
$JULIA -e 'using Pkg;Pkg.add("JUDI");Pkg.build("JUDI")' # JUDI will install devito and pyrevolve of desired versions
$JULIA -e 'using Pkg;Pkg.add.(["Statistics","Random","LinearAlgebra","Interpolations","DelimitedFiles","Distributed","SlimOptim","NLopt","HDF5","SegyIO","Plots","PyPlot","ImageFiltering","SetIntersectionProjection","ClusterManagers","ArgParse"])'
