# rds-poc

POC of remote store in Terraform with RDS and EC2 instances

**Diagram**

![Diagram](diagram.png)

**Pre-Requisites**

* Configure your `AWS_ACCESS_KEY_ID` and your `AWS_SECRET_ACCESS_KEY`
```
 export AWS_ACCESS_KEY_ID=XXXXXXXXX
 export AWS_SECRET_ACCESS_KEY=XXXXXXXXX
```
* Create your Key Pair on the region where is going to be deployed the solution

**Steps**
* On bucket_s3 directory:
  - Update the archive "vars.tf" with your bucket name to store .tfstate

  - After, you can run the following commands:
```
    $ terraform init
    $ terraform plan
    $ terraform apply
```
* On main directory:
  - Update the archive "vars.tf" to set the following variables:
    - ssh_key_name: The name of your ssh key to access the EC2 instance
    - ssh_public_key_path: Path where your public key is stored
    - postgre_db_name: Name of PostgreSQL DB
    - postgre_user: User of PostgreSQL DB
    - postgre_passwd: Password of user on PostgreSQL DB (min. 8 chars.)
    - user_data_base64: The script that will be executed on EC2 instance boot (need to be encoded in base64)
    
  - After, you will execute "terraform init" with the following parameter:
    ```
    $ terraform init -backend-config="bucket_name_created_in_bucket_s3"
    ```
  - As alternative, you can get the bucket name using the following command:
    ```
    $ terraform init \
        -backend-config="bucket=$(grep "default" ../bucket_s3/vars.tf | cut -d '"' -f2)"
    ```
  - After, you can execute the following steps
    ```
    $ terraform plan
    $ terraform apply
    ```

After the execution, a file name "addresses.txt" will be created in main directory with RDS endpoint, DB name and EC2 public IP.
