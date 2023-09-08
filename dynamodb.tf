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
