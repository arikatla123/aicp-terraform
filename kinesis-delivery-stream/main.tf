resource "aws_kinesis_firehose_delivery_stream" "aicp_s3_delivery_stream" {

  for_each    = var.firehoses
  name        = each.key
  destination = "s3"

  s3_configuration {
    role_arn           = aws_iam_role.firehose_iam_role.arn
    bucket_arn         = aws_s3_bucket.delivery_stream_s3_bucket.arn
    prefix             = each.value.s3_bucket_prefix
    buffer_size        = 1
    buffer_interval    = 60
    compression_format = "GZIP"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/${each.value.cloudwatch_logname}"
      log_stream_name = "S3Delivery"
    }
  }


  tags = {
    environmet = "staging"
    project    = "digital_twin"
  }
}

resource "aws_s3_bucket" "delivery_stream_s3_bucket" {
  bucket = var.delivery_stream_s3_bucket
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    environmet = "staging"
    project    = "aicp"
  }
}

resource "aws_cloudwatch_log_group" "firehose_log_group" {
  for_each    = var.firehoses
  name = "/aws/kinesisfirehose/${each.key}"
}

resource "aws_cloudwatch_log_stream" "firehose_s3_log_stream" {
  for_each    = var.firehoses
  name = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.firehose_log_group[each.key].name
  depends_on = [aws_cloudwatch_log_group.firehose_log_group]
}


resource "aws_iam_role" "firehose_iam_role" {
  name               = "firehose_role"
  assume_role_policy = file("firehose_iam_role.json")

  tags = {
    environmet = "staging"
    project    = "aicp"
  }
}

data "template_file" "firehose_iam_role_policy_file" {
  template = file("firehose_iam_role_policy.json")

  vars = {
    account_id = var.aws_account_id
    aws_s3_key = var.s3_kms_key
  }
}

resource "aws_iam_role_policy" "firehose_iam_role_policy" {
  name   = "fb_firehose_iam_policy"
  role   = aws_iam_role.firehose_iam_role.id
  policy = data.template_file.firehose_iam_role_policy_file.rendered
}
