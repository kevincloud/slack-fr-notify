data "archive_file" "notifyapp_zip" {
  type             = "zip"
  source_dir       = "${path.module}/notifyapp"
  excludes         = ["${path.module}/notifyapp/lambda_notifyapp.zip"]
  output_file_mode = "0666"
  output_path      = "${path.module}/notifyapp/lambda_notifyapp.zip"
}

resource "aws_lambda_function" "lambda_notifyapp" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename         = "${path.module}/notifyapp/lambda_notifyapp.zip"
  function_name    = local.notifyapp_fname
  role             = aws_iam_role.lambda_iam_role.arn
  handler          = "lambda_notifyapp.lambda_handler"
  source_code_hash = data.archive_file.notifyapp_zip.output_base64sha256
  runtime          = "python3.9"
  environment {
    variables = {
      PENDO_ID      = "${var.unique_identifier}-pendo-lastid"
      DDB_TABLE     = aws_dynamodb_table.fr_notify_table.name
      LOG_GROUP     = local.notifyapp_loggroup
      PENDO_KEY     = var.pendo_api_key
      SLACK_WEBHOOK = var.slack_webhook
    }
  }

  depends_on = [
    data.archive_file.notifyapp_zip
  ]
}

resource "aws_cloudwatch_log_group" "lambda_log_notifyapp" {
  name              = local.notifyapp_loggroup
  retention_in_days = 14
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_cloudwatch_log_stream" "lambda_logstream_notifyapp" {
  name           = "ApplicationLogs"
  log_group_name = aws_cloudwatch_log_group.lambda_log_notifyapp.name
}

resource "aws_iam_role" "lambda_iam_role" {
  name = "${var.unique_identifier}-iam-for-lambda"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : "sts:AssumeRole",
        Effect : "Allow",
        Principal : {
          "Service" : "lambda.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "lambda_access_policy" {
  statement {
    sid       = "FullAccess"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:Get*",
      "dynamodb:Update*",
      "s3:*"
    ]
  }
}

resource "aws_iam_policy" "lambda_logging_policy" {
  name = "lambda-logging-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect : "Allow",
        Resource : "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_iam_access_policy" {
  name   = "${var.unique_identifier}-lambda-access-policy"
  role   = aws_iam_role.lambda_iam_role.id
  policy = data.aws_iam_policy_document.lambda_access_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_iam_role.id
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}
