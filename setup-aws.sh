# Setting up Neo4j in AWS
# https://neo4j.com/developer/neo4j-cloud-aws-ec2-ami/

# Ensure that you have a "develop" profile setup, this points to wishabi-dev
alias awsdev='aws --profile develop'

# Create EC2 Key Pair for us to SSH into the instance
# https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#KeyPairs
export KEY_NAME='Neo4j-ConnectChickenHackathon'
awsdev ec2 create-key-pair \
  --key-name $KEY_NAME \
  --query 'KeyMaterial' \
  --output text > $KEY_NAME.pem
chmod 600 $KEY_NAME.pem

# Create a security grp - to control access to the instance
# https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#SecurityGroups:sort=groupId
export GROUP='neo4j-connect-sg'
awsdev ec2 create-security-group \
  --group-name $GROUP \
  --description 'Neo4j-ConnectChickenHackathon security group'

# Open up the Neo4j HTTP/HTTPs and Bolt ports + SSH port to remote access
# TCP, HTTP, HTTPs, Bolt
for port in 22 7474 7473 7687; do
  awsdev ec2 authorize-security-group-ingress --group-name $GROUP --protocol tcp --port $port --cidr 0.0.0.0/0
done

# Locate AMI Id to launch
# https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;search=neo4j-community-1-3.5.1;ownerAlias=385155106615;sort=name
# https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;search=neo4j-comm;sort=name
# Query below returns this for the MOST recent version of neo4j CE (4)
awsdev ec2 describe-images \
   --region us-east-1 \
   --filters 'Name=name,Values=*neo4j-community-1-4*' \
   --query 'Images[*].{ImageId:ImageId,Name:Name,CreationDate:CreationDate,OwnerId:OwnerId}'

export KEY_NAME='Neo4j-ConnectChickenHackathon'
export GROUP='neo4j-connect-sg'
# Start up the instance!
export AMI_ID='ami-003d6babe856fc5a8'
export INSTANCE_TYPE='r5.large'
export REGION='us-east-1'
awsdev ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-groups $GROUP \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=UNSTABLE-ConnectChickenHackathon - Neo4J}]' \
  --query 'Instances[*].InstanceId' \
  --region $REGION

# 
# user: neo4j
# password: i-06ed502876dc17ba1
# password: connect1234

# user: connect
# password: connect1234
ssh -i $KEY_NAME.pem ubuntu@ec2-3-81-63-54.compute-1.amazonaws.com


##### SSHED IN #####
# Change the password
#Default password is either $AWSINSTANCEID or neo4j
AWSINSTANCEID=$(curl -f -s http://169.254.169.254/latest/meta-data/instance-id)
curl -v -H 'Content-Type: application/json' \
  -XPOST -d '{"password":"'connect1234'"}' \
  -u neo4j:"$AWSINSTANCEID" \
  http://localhost:7474/user/neo4j/password 2>&1 | grep '200 OK''
  '

# Manage with sudo service
sudo service neo4j {start|stop|status|restart|force-reload}

scp -i Neo4j-ConnectChickenHackathon.pem ./imports/search_terms.csv ubuntu@ec2-3-81-63-54.compute-1.amazonaws.com:~
scp -i Neo4j-ConnectChickenHackathon.pem ./imports/user_info.csv ubuntu@ec2-3-81-63-54.compute-1.amazonaws.com:~

sudo mv *.csv /var/lib/neo4j/import/

# RAM
htop

# FS usage
df -hT /dev/xvda1
# Filesystem     Type  Size  Used Avail Use% Mounted on
# /dev/xvda1     ext4  7.7G  4.8G  3.0G  62% /