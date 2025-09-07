variable "step_function_arn" {
  description = "The ARN of the Step Function state machine to be triggered."
  type        = string
}

variable "name_prefix" {
  description = "A prefix for resource names to ensure uniqueness."
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}