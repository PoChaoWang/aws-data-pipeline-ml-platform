
# This file defines the scheduled trigger for the ML pipeline Step Function.

# 1. EventBridge Rule: Triggers daily at 08:00 UTC.
# Note: The time is in UTC. Please adjust the cron expression if you need a different timezone.
# For example, for UTC+8 8:00 AM, you would use "cron(0 0 * * ? *)".
resource "aws_cloudwatch_event_rule" "daily_ml_pipeline_trigger" {
  name                = "daily-ml-pipeline-trigger"
  description         = "Triggers the ML pipeline every day at 08:00 UTC"
  schedule_expression = "cron(0 8 * * ? *)"
}

# 2. IAM Role for EventBridge to assume, allowing it to start the Step Function.
resource "aws_iam_role" "eventbridge_sfn_executor" {
  name = "EventBridge-StepFunction-Executor-Role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

# 3. IAM Policy: Defines the permission to start the specific Step Function.
resource "aws_iam_policy" "sfn_start_execution_policy" {
  name        = "StepFunction-StartExecution-Policy"
  description = "Allows starting the ML pipeline Step Function"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = "states:StartExecution",
        Effect   = "Allow",
        Resource = var.step_function_arn # Reference to the state machine ARN
      }
    ]
  })
}

# 4. Attach the policy to the role.
resource "aws_iam_role_policy_attachment" "sfn_executor_attachment" {
  role       = aws_iam_role.eventbridge_sfn_executor.name
  policy_arn = aws_iam_policy.sfn_start_execution_policy.arn
}

# 5. Event Target: Connects the rule to the Step Function state machine.
resource "aws_cloudwatch_event_target" "trigger_sfn_target" {
  rule      = aws_cloudwatch_event_rule.daily_ml_pipeline_trigger.name
  target_id = "TriggerMLPipeline"
  arn       = var.step_function_arn
  role_arn  = aws_iam_role.eventbridge_sfn_executor.arn
}
