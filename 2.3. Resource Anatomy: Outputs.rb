=begin

Resource Anatomy: Outputs
===========================

The output definition consists of the following elements:

* The `output` keyword (which is actually a class method, ed.)
* The output definition, combining the resource name and property
* Code block (optional) for configuring the output

=end


class Stack < Halloumi::CompoundResource

  # The output example below won't be value without this property, as
  # explained in the 'Resource Anatomy: Properties.rb' example.
  property :cidr,
         env: :CIDR,
         default: "10.0.0.0/16"

  # The output example below won't be value without this resource, as
  # explained in the 'Resource Anatomy: Properties.rb' example.
  resource :vpcs, type: Halloumi::AWS::EC2::VPC do |r|
    r.property(:cidr_block) { cidr }
  end

  # A simple example, we define a single output.
  # We use the plural name `vpcs`, as used for the resource above.
  # We specify the name as a Ruby symbol (best practice).
  #
  # The property 'cidr' in this example will be outputted.
  output(:vpcs, :cidr) { |r| r.cidr_block }
end
