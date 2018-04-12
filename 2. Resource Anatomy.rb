=begin

Resource Anatomy
================
A Halloumi resource is a _class_. On this class you can define various things like properties, resources, and outputs, which we will discuss individually later.

This compiler service compiles the class named `Stack`, so you have to define that class here. Normally you would have been free to choose any name you like.

=end


class Stack < Halloumi::CompoundResource
  property :cidr, default: "10.0.0.0/16"
  
  resource :vpcs, type: Halloumi::AWS::EC2::VPC do |r|
    r.property(:cidr_block) { cidr }
  end
  
  output(:vpcs, :cidr) { |r| r.cidr_block }
end
