# This example builds a VPC, with VPC Flow Logs enabled.

class Stack < Halloumi::CompoundResource
    # Let us start with building a VPC resource.
    resource :vpcs,
             type: Halloumi::AWS::EC2::VPC do |r|
        r.property(:cidr_block) { "10.0.0.0/16" }
    end

    # The AWS::EC2::FlowLog resource requires permissions
    # to create Log Groups and write logs to CloudWatch.
    # We create the IAM Role here, and reference it
    # in the AWS::EC2::FlowLog resource.
    resource :vpc_flow_log_policys,
             type: Halloumi::AWS::IAM::Role do |r|
        r.property(:path) { "/" }
        r.property(:assume_role_policy_document) do
            {
                Version: "2012-10-17",
                Statement: [
                    {
                        Effect: :Allow,
                        Principal: {
                            Service: "vpc-flow-logs.amazonaws.com"
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
                    PolicyName: "FlowLogPolicy",
                    PolicyDocument: {
                        Statement: [
                            {
                                Action: [
                                    "logs:CreateLogGroup",
                                    "logs:CreateLogStream",
                                    "logs:PutLogEvents",
                                    "logs:DescribeLogGroups",
                                    "logs:DescribeLogStreams"
                                ],
                                Effect: :Allow,
                                Resource: "*"
                            }
                        ]
                    }
                }
            ]
        end
    end

    # We create a LogGroup with a custom log group name
    # and set the retention of the VPC flow logs to 30 days.
    resource :vpc_flow_log_groups,
        type: Halloumi::AWS::Logs::LogGroup do |r|
        r.property(:log_group_name) { "/aws/vpc/VPCFlowLogs" }
        r.property(:retention_in_days) { 30 }
    end

    # Finally, we create the VPC FlowLog resource.
    resource :vpc_flow_logs,
             type: Halloumi::AWS::EC2::FlowLog do |r|
        r.property(:deliver_logs_permission_arn) { vpc_flow_log_policy.ref_arn }
        r.property(:log_group_name) { vpc_flow_log_group.ref }

        # The ID of the subnet, network interface, or VPC for which you want to
        # create a flow log. In this case we reference the VPC we created.
        r.property(:resource_id) { vpc.ref }

        # Type type of resource to create flow logs for.
        # This can be one of 'VPC', 'Subnet' or 'NetworkInterface'.
        r.property(:resource_type) { "VPC" }

        # Type of traffic to log.
        # This can be one of 'ACCEPT', 'REJECT' or 'ALL'.
        r.property(:traffic_type) { "ALL" }
    end
end
