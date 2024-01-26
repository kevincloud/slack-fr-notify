resource "aws_dynamodb_table" "fr_notify_table" {
  name           = "${var.unique_identifier}-pendo-data"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "AppId"

  attribute {
    name = "AppId"
    type = "S"
  }

  tags = {
    Name  = "${var.unique_identifier}-pendo-data"
    owner = var.owner
  }
}

############################################################
# The following resource creates data in the DynamoDB table
# to initialize it. However, it's best not to include it in 
# this configuration since any future updates to the data 
# in the table will be overwritten by this resource. If 
# this resource is removed/commented out from this config, 
# the data will be deleted.
############################################################

# resource "aws_dynamodb_table_item" "initial_ddb_item" {
#   table_name = aws_dynamodb_table.fr_notify_table.name
#   hash_key   = aws_dynamodb_table.fr_notify_table.hash_key

#   item = <<ITEM
# {
#     "AppId": {"S": "${var.unique_identifier}-pendo-lastid"},
#     "NumberItem": {"N": "318714"}
# }
# ITEM
# }
