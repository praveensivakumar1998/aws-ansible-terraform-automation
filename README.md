# To automate windows installation and configuration to my ec2 servers using ansible and terraform 
I'm going to install and configure Nginx and configure port using ansible and creating infrastructure using terraform as a test project to memorize my learnings


### Pre-requistes:
Create a IAM user with respective user permissions and generate credentials for cli configuration in management server

## Step 1: Install ansible and terraform in aws environment in ubuntu server
![image](https://github.com/praveensivakumar1998/aws-ansible-terraform-automation/assets/108512714/ff5a22c1-c2b2-4470-b470-225a455a93bc)

### use this userdata scripts when instance launch to install aws cli, git, ansible and terraform 
```
#!bin/bash

sudo apt-get update
sudo apt-get upgrade

#Install awscli
sudo apt install awscli -y

#Install git 
sudo apt install git -y

#Install ansible
sudo apt install ansible -y

#Install terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

## Step 2:
### Log in to the Ubuntu server
![image](https://github.com/praveensivakumar1998/aws-ansible-terraform-automation/assets/108512714/963c044d-891b-4785-8511-da46ddb30a9d)

check the packages are installed correctly in a server by userdata push
```
ansible --version
aws --version
terraform --version
git --version
```
![image](https://github.com/praveensivakumar1998/aws-ansible-terraform-automation/assets/108512714/3016a609-b598-446e-b1eb-da42316c671b)


## Step 3:
**configure aws cli**
```
aws configure
```
![image](https://github.com/praveensivakumar1998/aws-ansible-terraform-automation/assets/108512714/ee31aacd-479a-4991-a2ea-8cc4ca071812)
update the credentials and region id

check the cli configuration is working fine 
```
aws s3 ls
```
## Step 4:
setup passwordless authentication to connect target server from management server
```
ssh-keygen
```
![image](https://github.com/praveensivakumar1998/aws-ansible-terraform-automation/assets/108512714/5dcb6dcc-994b-419a-a9f5-63209306e98a)

copy publickey to authenticate target servers, the file stored in .ssh path
```
cat .ssh/id_rsa.pub
```
![image](https://github.com/praveensivakumar1998/aws-ansible-terraform-automation/assets/108512714/5a774b93-aa58-4544-a097-978889eaa812)

copy the public key content and stored in local notepad file
Create s3 bucket and upload the publickey in the bucket location 
make sure to enable the object as public to download


## Step 5: Clone this git repository
```
git clone https://github.com/praveensivakumar1998/aws-ansible-terraform-automation.git
```

## Step 6: Create Target servers using terraform

```
cd aws-ansible-terraform-automation/terraform
```
# configure terraform

### initialize terraform
```
terraform init
```

![image](https://github.com/praveensivakumar1998/aws-ansible-terraform-automation/assets/108512714/ce8159e7-609a-4f2e-af35-531a8badc7f9)

make sure to update s3 object link to the main.tf userdata 
![image](https://github.com/praveensivakumar1998/aws-ansible-terraform-automation/assets/108512714/fe2cc401-f6f8-4260-a782-846d71fdf224)
```
terraform plan
```

![image](https://github.com/praveensivakumar1998/aws-ansible-terraform-automation/assets/108512714/b729bbbe-a213-4cc0-aa3e-667f5fedb631)
```
terraform apply
```
![image](https://github.com/praveensivakumar1998/aws-ansible-terraform-automation/assets/108512714/763d1a5c-5173-459f-b7f7-c14a9a21535c)

check the console target instances will created as per terraform configuration
![image](https://github.com/praveensivakumar1998/aws-ansible-terraform-automation/assets/108512714/3e50feb5-db39-421d-a54d-cbe36724d688)

# now automate the installation to those target servers using ansible
check can able to connect the target servers in management server
![image](https://github.com/praveensivakumar1998/aws-ansible-terraform-automation/assets/108512714/17a7c5fc-158a-4648-854a-bc589a902d22)

cd /home/ubuntu/aws-ansible-terraform-automation/ansible

update the target server private ip in ansible inventory 

nano inventory
![image](https://github.com/praveensivakumar1998/aws-ansible-terraform-automation/assets/108512714/39327438-1749-4823-bf8c-7b582c351df6)

seperated by webservers and dbservers

ansible-playbook -i inventory playbook.yml
![image](https://github.com/praveensivakumar1998/aws-ansible-terraform-automation/assets/108512714/087c9b73-8fb1-421f-9180-284b3d44380e)

check the installation and configuration is applied on target servers

all working fine, finally terminate your test servers and other resources created from terraform to reduce cost in aws environment

cd cd /home/ubuntu/aws-ansible-terraform-automation/

terraform destroy
![image](https://github.com/praveensivakumar1998/aws-ansible-terraform-automation/assets/108512714/2780b410-90ee-4dd7-89bb-ff68beb70949)




