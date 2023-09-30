# Configuration SLURM cluster

Here are the steps to prepare master and compute nodes from scratch.

## Clean VM

First of all generate SSH-keys for accesing other VM in the net (use default filename):
```
ssh-keygen -t ed25519
```
add it to the authorized keys:
```
cd ~/.ssh
cat id_ed25519.pub >> authorized_keys
```
To avoid always typing password to VM in net type (needed to be run on every session):
```
ssh-agent bash
ssh-add ~/.ssh/id_ed25519
```

### Fast start

1. Install common deps for master and compute nodes:
```
cd ~/config
chmod +x common_setup.sh
./common_setup.sh
```
2. Shutdown the machine and create disk image
3. Fill `/etc/ansible/hosts` with your nodes data to be able to use Ansible
4. Create group of nodes from that image
5. Launch master and compute nodes
6. Configure all master nodes (may take half of and hour to install build python, install julia and deps, use `htop` to watch what processes are running):
```
ansible-playbook ~/config/prepare_master_nodes.yml
```
7. Configure all compute nodes:
```
ansible-playbook ~/config/prepare_compute_nodes.yml
```
8. Finish configuration by setting `~/config/slurm.conf` and running:
```
ansible-playbook ~/config/slurm-start.yml
```

### Long start

1. Install prerequisites along with python and julia:
```
cd ~/config
chmod +x prerequisites.sh
./prerequisites.sh
```
2. Shut down the master node and create snapshot from the disk
3. Create group of nodes from that snapshot so all the deps will already be preinstalled on all the nodes. 
4. Run master and compute nodes.
5. Install Ansible on master node:
```
sudo yum install epel-release
sudo yum install ansible
```
6. Edit Ansible inventory file to include all the compute nodes with their private IP:
```
sudo nano /etc/ansible/hosts
```
by appending lines similar to this:
```
[masternodes]
master ansible_host=10.128.0.22

[computenodes]
node1 ansible_host=10.128.0.24
node2 ansible_host=10.128.0.29
```
To check availability of servers (nodes) use the command: `ansible all -m ping -u kerim`.

7. Make `~/shared` folder with (on master).
Run service and add it to startup (requires `nfs-utils` package):
```
sudo systemctl enable rpcbind
sudo systemctl enable nfs-server
sudo systemctl start rpcbind
sudo systemctl start nfs-server
```
make `~/shared` dir and add this line `/home/kerim/shared *(rw,sync,no_root_squash,no_subtree_check)` to the file `/etc/exports`
```
# add:
# /home/kerim/shared *(rw,sync,no_root_squash,no_subtree_check)
mkdir -p ~/shared
sudo chmod -R 777 ~/shared
sudo nano /etc/exports
```
then:
```
sudo exportfs -a
sudo systemctl restart nfs
```
Also open ports if firewall is installed:
```
firewall-cmd --permanent --add-port=111/tcp
firewall-cmd --permanent --add-port=20048/tcp
firewall-cmd --permanent --zone=public --add-service=nfs
firewall-cmd --permanent --zone=public --add-service=mountd
firewall-cmd --permanent --zone=public --add-service=rpc-bind
firewall-cmd --reload
```
Then on computing nodes add services to startup:
```
sudo systemctl enable rpcbind
sudo systemctl enable nfs-server
sudo systemctl start rpcbind
sudo systemctl start nfs-server
```
create and mount this directory (use Ansible for that: `ansible-playbook /home/kerim/config/shared-dir-setup.yml`):
```
mkdir -p /home/kerim/shared
sudo mount -t nfs master-fwi:/home/kerim/shared /home/kerim/shared
```
and make automount automatic at startup:
```
# add:
# master-fwi:/home/kerim/shared/ /home/kerim/shared/ nfs rw,sync,hard,intr 0 0
nano /etc/fstab
```
8. Install SLURM and MUNGE:
```
cd ~/config
chmod +x SLURM_installation.sh
./SLURM_installation.sh
```
9. Edit `/etc/slurm/slurm.conf` by setting all the nodes info at the bottom of the file and copy this file to all nodes or make this folder shared as well.
Use `lcpu` to get info about CPU in CentOS 7. Here is the example of how it may look:
```
# COMPUTE NODES
NodeName=master-fwi.ru-central1.internal State=idle Feature=dcv2,other CPUs=2 Sockets=1 CoresPerSocket=1 ThreadsPerCore=2 
NodeName=cl1cfqj5m64qsem9ra43-ukeq.ru-central1.internal CPUs=2 Sockets=1 CoresPerSocket=1 ThreadsPerCore=2 State=UNKNOWN
NodeName=cl1cfqj5m64qsem9ra43-ecaj.ru-central1.internal CPUs=2 Sockets=1 CoresPerSocket=1 ThreadsPerCore=2 State=UNKNOWN

PartitionName=debug Nodes=ALL Default=YES MaxTime=INFINITE State=UP
```
NOTE: don't forget to set `SlurmctldHost` at the top with the name of `master`.

10. Be sure that all nodes have same `/etc/munge/munge.key`. 
Depending on the `munge` version there may either be `create-munge-key` utility or `mungekey`. 
Pass flag `-f` to overwrite this file.
11. Read `~/config/SLURM_installation.sh` to run several commands that are not in common for master and compute nodes.
12. After slurm is started run `sinfo` and `srun hostname` to be sure that it works correctly.

# NOTE: to run Julia distributed with ClusterManager make sure that you are located in shared folder