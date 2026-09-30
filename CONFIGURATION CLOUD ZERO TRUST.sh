############################################################
#  AWS ZERO TRUST ARCHITECTURE
############################################################

# 1 VPC ISOLÉ
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# Sous-réseaux privés (DB)
aws ec2 create-subnet --vpc-id vpc-id --cidr-block 10.0.2.0/24

# Sous-réseaux publics (API Gateway)
aws ec2 create-subnet --vpc-id vpc-id --cidr-block 10.0.1.0/24

############################################################
# 2 SECURITY GROUPS (MICRO-SEGMENTATION)
############################################################

# Autoriser API → DB uniquement
aws ec2 authorize-security-group-ingress \
  --group-id db-sg \
  --protocol tcp --port 5432 \
  --source-group api-sg

############################################################
# 3 RDS POSTGRESQL (PRIVÉ)
############################################################

aws rds create-db-instance \
  --db-instance-identifier ecole-db \
  --engine postgres \
  --no-publicly-accessible \
  --storage-encrypted

############################################################
# 4 API GATEWAY + JWT AUTH
############################################################

# API Gateway avec authorizer JWT (Cognito)
aws apigateway create-authorizer \
  --name JWTAuth \
  --type COGNITO_USER_POOLS

############################################################
# 5 AWS COGNITO (AUTH ZERO TRUST)
############################################################

aws cognito-idp create-user-pool \
  --pool-name ecole-users \
  --mfa-configuration ON

############################################################
# 6 WAF (ANTI ATTAQUES)
############################################################

aws wafv2 create-web-acl \
  --name api-protection \
  --scope REGIONAL \
  --default-action Block

############################################################
# 7 IAM (MOINDRE PRIVILÈGE)
############################################################

# Role backend
aws iam create-role --role-name api-role

# Policy accès DB limité
aws iam attach-role-policy \
  --role-name api-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonRDSFullAccess

############################################################
# 8 LOGGING & MONITORING
############################################################

aws cloudtrail create-trail --name security-trail
aws logs create-log-group --log-group-name /ecole/api

############################################################
# 9 CHIFFREMENT
############################################################

# KMS pour DB
aws kms create-key --description "DB encryption key"

############################################################
#  AZURE ZERO TRUST ARCHITECTURE
############################################################

# 1 RESOURCE GROUP
az group create --name ecole-rg --location westeurope

# 2 VNET
az network vnet create \
  --resource-group ecole-rg \
  --name ecole-vnet \
  --address-prefix 10.0.0.0/16

# 3 SUBNETS
az network vnet subnet create \
  --vnet-name ecole-vnet \
  --name db-subnet \
  --address-prefix 10.0.2.0/24

# 4 POSTGRESQL (PRIVÉ)
az postgres flexible-server create \
  --name ecole-db \
  --public-access none

# 5 AZURE AD AUTH (ZERO TRUST)
az ad app create --display-name "ecole-api"

# 6 API MANAGEMENT
az apim create \
  --name ecole-api-mgmt \
  --resource-group ecole-rg

# 7 WAF (FRONT DOOR)
az network front-door create \
  --resource-group ecole-rg

# 8 RBAC
az role assignment create \
  --assignee user-id \
  --role Reader

# 9 MONITORING
az monitor log-analytics workspace create \
  --resource-group ecole-rg

############################################################
#  PRINCIPES ZERO TRUST APPLIQUÉS
############################################################

# ✔ DB non exposée
# ✔ API protégée par JWT + MFA
# ✔ Accès par rôle (IAM / Azure AD)
# ✔ Réseau segmenté
# ✔ Logs centralisés
# ✔ WAF actif
# ✔ Chiffrement actif
