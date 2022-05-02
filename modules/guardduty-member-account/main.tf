# Create GuardDuty detector for the member account
resource "aws_guardduty_detector" "this" {
  enable = var.enable
}

# Create GuardDuty member in the administrator account
resource "aws_guardduty_member" "this" {
  count = var.member == null ? 0 : 1

  provider = aws.administrator

  account_id                 = aws_guardduty_detector.this.account_id
  detector_id                = data.aws_guardduty_detector.administrator.id
  email                      = var.member.email
  invite                     = var.member.invite
  invitation_message         = var.member.invitation_message
  disable_email_notification = var.member.disable_email_notification

  timeouts {
    create = "60s"
    update = "60s"
  }

  lifecycle {
    ignore_changes = [
      # For why this is necessary, see https://github.com/hashicorp/terraform-provider-aws/issues/8206
      invite,
      disable_email_notification,
      invitation_message,
    ]
  }
}

# Create GuardDuty invite accepter in the member account
resource "aws_guardduty_invite_accepter" "this" {
  count = var.member == null ? 0 : 1

  detector_id       = aws_guardduty_detector.this.id
  master_account_id = data.aws_caller_identity.administrator.account_id

  depends_on = [aws_guardduty_member.this]
}

data "aws_guardduty_detector" "administrator" {
  provider = aws.administrator
}

data "aws_caller_identity" "administrator" {
  provider = aws.administrator
}