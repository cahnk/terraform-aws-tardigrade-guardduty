module "guardduty_threatintelset_ipset_filter" {
  source = "../../"

  enable = true

  filter = {
    name        = "MyFilter"
    description = "My Filter"
    rank        = 1
    action      = "ARCHIVE"
    tags = {
      environment = "testing"
    }
    criterion = [
      {
        field                 = "severity"
        equals                = ["4"]
        not_equals            = ["1"]
        greater_than          = null
        greater_than_or_equal = null
        less_than             = null
        less_than_or_equal    = null
      }
    ]
  }

  threatintelset = {
    name     = "MyThreatIntelSet"
    activate = true
    format   = "TXT"
    location = "https://s3.amazonaws.com/${aws_s3_object.MyThreatIntelSet.bucket}/${aws_s3_object.MyThreatIntelSet.key}"
    tags = {
      environment = "testing"
    }
  }

  ipset = {
    name     = "MyIpset"
    activate = true
    format   = "TXT"
    location = "https://s3.amazonaws.com/${aws_s3_object.ipSet.bucket}/${aws_s3_object.ipSet.key}"
    tags = {
      environment = "testing"
    }
  }

  publishing_destination = {
    destination_arn  = aws_s3_bucket.bucket.arn
    kms_key_arn      = aws_kms_key.gd_key.arn
    destination_type = "S3"
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "bucket_pol" {
  statement {
    sid = "Allow PutObject"
    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.bucket.arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }

  statement {
    sid = "Allow GetBucketLocation"
    actions = [
      "s3:GetBucketLocation"
    ]

    resources = [
      aws_s3_bucket.bucket.arn
    ]

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "kms_pol" {

  statement {
    sid = "Allow GuardDuty to encrypt findings"
    actions = [
      "kms:GenerateDataKey"
    ]

    resources = [
      "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }

  statement {
    sid = "Allow all users to modify/delete key (test only)"
    actions = [
      "kms:*"
    ]

    resources = [
      "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "random_id" "name" {
  byte_length = 6
  prefix      = "tardigrade-s3-bucket-"
}

resource "aws_s3_bucket" "bucket" {
  bucket        = random_id.name.hex
  force_destroy = true
  tags = {
    environment = "testing"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "gd_bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket_pol.json
}

resource "aws_kms_key" "gd_key" {
  description             = "Temporary key for AccTest of TF"
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.kms_pol.json
}

resource "aws_s3_object" "MyThreatIntelSet" {
  acl     = "public-read"
  content = "10.0.0.0/8\n"
  bucket  = aws_s3_bucket.bucket.id
  key     = "MyThreatIntelSet"
}

resource "aws_s3_object" "ipSet" {
  acl     = "public-read"
  content = "10.0.0.0/8\n"
  bucket  = aws_s3_bucket.bucket.id
  key     = "MyIpSet"
}