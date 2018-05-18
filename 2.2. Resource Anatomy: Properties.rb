=begin

Resource Anatomy: Properties
===========================

The name of the property must be passed as the first argument to this property, using lowercase characters and optionally underscores.

The property definition consists of the following elements:

  * The `property` keyword (which is actually a class method, ed.)
  * Keyword arguments (type is compulsory)
  * Code block (optional) for configuring the property

A property can have the following keyword arguments:

  * `env` the property value optionally can come from the environment file, for example '.env.test'. This value is defined uppercase.
  * `default` you can optionally define a default, that will be used whenever there's no value defined.

Properties can be set in the block of a resource definition by using the object instance method property on a Halloumi::CompoundResource

AWS Cloudformation property documentation for the resource example: [VPC properties](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc.html).

Defining a resource property in resource instance 'r' will always be in lowercase using underscores. For example using the 'CidrBlock' property Example
in the Cloudformation documentation will become 'r.cidr_block'

Examples:
'CidrBlock' (Cloudformation documentation), will become 'r.cidr_block' (Halloumi)
'EnableDnsHostnames' (Cloudformation documentation), will become 'r.enable_dns_hostnames' (Halloumi)

=end


class Stack < Halloumi::CompoundResource

  # A simple example, we define a single CIDR property,
  # with a default.
  # The name used can be anything, in this case 'cidr'.
  # We specify the name as a Ruby symbol (best practice).
  property :cidr,
         env: :CIDR,
         default: "10.0.0.0/16"

  # Example usage of the property 'cidr' in a VPC resource.
  # To check which properties are available for this resource type, lookup the
  # type, without the 'Halloumi::' part, so in this case,
  # google for: 'AWS::EC2::VPC Cloudformation'.
  resource :vpcs, type: Halloumi::AWS::EC2::VPC do |r|

    # A property is always defined in between brackets. Everything in between
    # the brackets will be evaluated on the Class type of whatever you insert.
    # Based on the Class type it will assign the value 'cidr' to the property.
    # Define the propery 'cidr_block' according the AWS Cloudformation
    # documentation.
    r.property(:cidr_block) { cidr }
  end
end
