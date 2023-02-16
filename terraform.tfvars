repo_name = "phpapplication_ecr_repo"
cidr_block_vpc = "10.10.0.0/16"
cidr_block_subnet1 = "10.10.10.0/24"
cidr_block_subnet2 = "10.10.11.0/24"
cidr_block_subnet3 = "10.10.12.0/24"
region     = "us-east-1"
az1 = "us-east-1a"
az2 = "us-east-1b"
az3 = "us-east-1c"
#keypair_name = ""
#access_key = ""
#secret_key = ""

engine               = "mysql"
engine_version       = "5.7"
instance_class       = "db.t3.micro"
db_name              = "mydb"
username             = "user1"
password             = "password"
parameter_group_name = "default.mysql5.7"

task_definition_cpu = 20
task_definition_memory = 2048
task_definition_network_mode = "awsvpc"
domain_name = "reachwebapp.com"


