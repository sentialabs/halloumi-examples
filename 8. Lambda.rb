# frozen_string_literal: true

class Stack < Halloumi::CompoundResource
  # @!group Properties
  property :alarm_email_addresses,
           filter: Halloumi::Filters.string_to_array,
           required: true,
           env: :ALARM_EMAIL_ADDRESSES,
           default: "john.doe@sentia.com"

  property :example_lambda_archive,
           env: :EXAMPLE_LAMBDA_ARCHIVE,
           required: true,
           default: "example-lambda-funtion.zip"

  property :example_lambda_bucket,
           env: :EXAMPLE_LAMBDA_BUCKET,
           required: true,
           default: "exampe-lambda-bucket"

  property :example_lambda_function_errors_alarm_threshold,
           env: :EXAMPLE_LAMBDA_ERRORS_ALARM_THRESHOLD,
           default: 1

  property :example_lambda_memory_size,
           env: :EXAMPLE_LAMBDA_MEMORY_SIZE,
           default: 128

  property :example_lambda_timeout,
           env: :EXAMPLE_LAMBDA_MEMORY_SIZE,
           default: 300

  # @!group Resources
  resource :example_lambda_alarm_topics,
           type: Halloumi::AWS::SNS::Topic do |r|
    r.property(:subscription) do
      alarm_email_addresses.map do |email_address|
        {
          Endpoint: email_address,
          Protocol: "email"
        }
      end
    end
  end

  resource :example_lambda_roles,
           type: Halloumi::AWS::IAM::Role do |r|
    r.property(:path) { "/" }
    r.property(:assume_role_policy_document) do
      {
        Version: "2012-10-17",
        Statement: [
          {
            Effect: :Allow,
            Principal: {
              Service: "lambda.amazonaws.com"
            },
            Action: [
              "sts:AssumeRole"
            ]
          }
        ]
      }
    end
    r.property(:policies) do
      [
        {
          PolicyName: "AllowLogs",
          PolicyDocument: {
            Statement: [
              {
                Action: [
                  "logs:CreateLogGroup",
                  "logs:CreateLogStream",
                  "logs:DeleteSubscriptionFilter",
                  "logs:PutLogEvents",
                  "logs:PutSubscriptionFilter",
                  "logs:TestMetricFilter"
                ],
                Effect: :Allow,
                Resource: "arn:aws:logs:eu-west-1:664774981888:*"
              }
            ]
          }
        },
        {
          PolicyName: "AllowEc2",
          PolicyDocument: {
            Statement: [
              {
                Action: [
                  "ec2:CreateNetworkInterface",
                  "ec2:DescribeNetworkInterfaces",
                  "ec2:DeleteNetworkInterface"
                ],
                Effect: :Allow,
                Resource: "*"
              }
            ]
          }
        },
        {
          PolicyName: "AllowLambaInvoke",
          PolicyDocument: {
            Statement: [
              {
                Effect: "Allow",
                Action: ["lambda:InvokeFunction"],
                Resource: "arn:aws:lambda:eu-west-1:664774981888:function:*"
              }
            ]
          }
        }
      ]
    end
  end

  resource :example_lamba_permissions,
           type: Halloumi::AWS::Lambda::Permission do |r|
    r.depends_on { [example_lambda_function._id] }
    r.property(:action) { "lambda:InvokeFunction" }
    r.property(:principal) { "events.amazonaws.com" }
    r.property(:source_arn) { example_lambda_event.ref_arn }
    r.property(:function_name) { example_lambda_function.ref }
  end

  resource :example_lambda_events,
           type: Halloumi::AWS::Events::Rule do |r|
    r.property(:schedule_expression) { "rate(1 day)" }
    r.property(:state) { "ENABLED" }
    r.property(:targets) do
      [
        {
          Arn: example_lambda_function.ref_arn,
          Id: example_lambda_function.ref
        }
      ]
    end
    r.property(:name) { "ExampleLambdaFunctionEvent" }
  end

  resource :example_lambda_functions,
           type: Halloumi::AWS::Lambda::Function do |r|
    r.depends_on { [example_lambda_role._id] }
    r.property(:code) do
      {
        S3Bucket: example_lambda_bucket,
        S3Key: example_lambda_archive
      }
    end
    r.property(:environment) do
      {
        Variables: {
          "EXAMPLE_VARIABLE_KEY" => "example_value"
        }
      }
    end
    r.property(:handler) { "index.lambda_handler" }
    r.property(:memory_size) { example_lambda_memory_size.to_i }
    r.property(:role) { example_lambda_role.ref_arn }
    r.property(:runtime) { "python3.6" }
    r.property(:timeout) { example_lambda_timeout.to_i }
  end

  resource :example_lambda_function_errors_alarms,
           type: Halloumi::AWS::CloudWatch::Alarm do |r|
    r.depends_on { [example_lambda_function._id, example_lambda_alarm_topic._id] }
    r.property(:alarm_actions) { example_lambda_alarm_topics.map(&:ref) }
    r.property(:alarm_description) { "Alarm for Example Lambda Function Errors" }
    r.property(:comparison_operator) { "GreaterThanOrEqualToThreshold" }
    r.property(:evaluation_periods) { 1 }
    r.property(:metric_name) { "Errors" }
    r.property(:dimensions) do
      [
        {
          Name: :FunctionName,
          Value: example_lambda_function.ref
        }
      ]
    end
    r.property(:namespace) { "AWS/Lambda" }
    r.property(:period) { 60 }
    r.property(:statistic) { "Sum" }
    r.property(:threshold) do
      example_lambda_function_errors_alarm_threshold
    end
    r.property(:treat_missing_data) { "notBreaching" }
  end

  resource :example_lambda_function_max_memory_used_metric_filters,
           type: Halloumi::AWS::Logs::MetricFilter do |r|
    r.depends_on { [example_lambda_function._id, example_lambda_alarm_topic._id] }
    r.property(:filter_pattern) { "[type=REPORT, ..., memory_used, size]" }
    r.property(:log_group_name) do
      {
        "Fn::Join": [
          "", [
            "/aws/lambda/",
            example_lambda_function.ref
          ]
        ]
      }
    end
    r.property(:metric_transformations) do
      [
        {
            MetricValue: "$memory_used",
            MetricNamespace: "Example/Lambda",
            MetricName: "ExampleLambdaFunctionMaxMemoryUsed"
        }
      ]
    end
  end

  resource :example_lambda_function_timed_out_metric_filters,
           type: Halloumi::AWS::Logs::MetricFilter do |r|
    r.depends_on { [example_lambda_function._id, example_lambda_alarm_topic._id] }
    r.property(:filter_pattern) { "Task timed out after" }
    r.property(:log_group_name) do
      {
        "Fn::Join": [
          "", [
            "/aws/lambda/",
            example_lambda_function.ref
          ]
        ]
      }
    end
    r.property(:metric_transformations) do
      [
        {
            MetricValue: 1,
            MetricNamespace: "Example/Lambda",
            MetricName: "ExampleLambdaFunctionTimedOut"
        }
      ]
    end
  end

  resource :example_lambda_function_max_memory_used_alarms,
           type: Halloumi::AWS::CloudWatch::Alarm do |r|
    r.depends_on { [example_lambda_function_max_memory_used_metric_filter._id, example_lambda_alarm_topic._id] }
    r.property(:alarm_actions) { example_lambda_alarm_topics.map(&:ref) }
    r.property(:alarm_description) { "Alarm for Example Lambda Function Max Memory Used" }
    r.property(:comparison_operator) { "GreaterThanOrEqualToThreshold" }
    r.property(:evaluation_periods) { 1 }
    r.property(:metric_name) { "ExampleLambdaFunctionMaxMemoryUsed" }
    r.property(:namespace) { "Example/Lambda" }
    r.property(:period) { 60 }
    r.property(:statistic) { "Maximum" }
    r.property(:threshold) { 128 }
    r.property(:treat_missing_data) { "notBreaching" }
  end

  resource :example_lambda_function_timed_out_alarms,
           type: Halloumi::AWS::CloudWatch::Alarm do |r|
    r.depends_on { [example_lambda_function_timed_out_metric_filter._id, example_lambda_alarm_topic._id] }
    r.property(:alarm_actions) { example_lambda_alarm_topics.map(&:ref) }
    r.property(:alarm_description) { "Alarm for Example Lambda Function Timed Out" }
    r.property(:comparison_operator) { "GreaterThanOrEqualToThreshold" }
    r.property(:evaluation_periods) { 1 }
    r.property(:metric_name) { "ExampleLambdaFunctionTimedOut" }
    r.property(:namespace) { "Example/Lambda" }
    r.property(:period) { 60 }
    r.property(:statistic) { "Sum" }
    r.property(:threshold) { 1 }
    r.property(:treat_missing_data) { "notBreaching" }
  end
end
