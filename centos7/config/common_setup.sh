# ======================================================
# INSTALL BASIC PACKAGES
sudo yum -y check-update
sudo yum -y install epel-release  # htop and ansible must be installed after `epel-release`
sudo yum -y install net-tools htop openmpi-devel nfs-utils nano git dnf ansible

# GCC and its deps
sudo dnf -y install bzip2 wget gcc gcc-c++ gmp-devel mpfr-devel libmpc-devel make 

# install python deps
sudo yum install openssl-devel bzip2-devel libffi-devel -y

# current script dir
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# install SLURM
chmod +x $SCRIPT_DIR/SLURM_installation.sh
source $SCRIPT_DIR/SLURM_installation.sh