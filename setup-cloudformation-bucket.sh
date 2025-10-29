#------------------------------------------------------------------------------#
REGION=us-east-1
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)


# ---------------- Configuration --------------------------------------------#
BUCKET_NAME="my-sus-apg-stacks-${REGION}-${ACCOUNT_ID}"  # unique bucket name

CHILD_STACKS_DIR="./child-stacks"     # directory with child stacks
echo "Creating S3 bucket: $BUCKET_NAME in region $REGION"
aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${REGION}"

aws s3api put-bucket-versioning --bucket "${BUCKET_NAME}" --versioning-configuration Status=Enabled
sleep 3
echo "Applying S3 bucket policy to allow CloudFormation access..."
POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFormationRead",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudformation.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": [
        "arn:aws:s3:::$BUCKET_NAME",
        "arn:aws:s3:::$BUCKET_NAME/*"
      ]
    }
  ]
}
EOF
)
aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy "$POLICY"
echo "Uploading child stack to S3..."
cd "${CHILD_STACKS_DIR}"
aws s3 cp "sus-domain-stack.yaml" "s3://$BUCKET_NAME/sus-domain-stack.yaml"
aws s3 cp "sus-blueprints-stack.yaml" "s3://$BUCKET_NAME/sus-blueprints-stack.yaml"
aws s3 cp "sus-project-stack.yaml" "s3://$BUCKET_NAME/sus-project-stack.yaml"
