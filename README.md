# mehlj-terraform

TF configuration files for DevOps testing architecture.

## Prerequisite
Make sure you have your AWS environment variables loaded before running. This can usually be done with `aws configure`.

### State
If you want to leverage S3 + DynamoDB for state, provision the resources in `state_bucket/` using `terraform init` and `terraform apply`.

## Initialization
```
$ terraform init
```

## Running
```
$ ./provision.sh -t /home/mehlj/git/mehlj-terraform/ -k /home/mehlj/git/kubespray/ -n mehlj-cluster -f ~/.vault_pass.txt
```
