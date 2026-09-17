data "aws_iam_policy_document" "node_termination" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:kube-system:aws-node-termination-handler"
      ]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "node_termination" {
  assume_role_policy = data.aws_iam_policy_document.node_termination.json
  name               = format("%s-node-termination-handler", var.project_name)
}

data "aws_iam_policy_document" "aws_node_termination_handler_policy" {
  version = "2012-10-17"

  statement {

    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstances",
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage"
    ]

    resources = [
      "*"
    ]

  }
}

resource "aws_iam_policy" "aws_node_termination_handler_policy" {
  name        = format("%s-_node_termination_handler", var.project_name)
  path        = "/"
  description = var.project_name

  policy = data.aws_iam_policy_document.aws_node_termination_handler_policy.json
}

resource "aws_iam_policy_attachment" "aws_node_termination_handler_policy" {

  name = "aws_node_termination_handler"
  roles = [
    aws_iam_role.node_termination.name
  ]

  policy_arn = aws_iam_policy.aws_node_termination_handler_policy.arn
}