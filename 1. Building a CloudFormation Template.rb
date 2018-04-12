=begin

Building a CloudFormation Template
==================================
Here we are going to use Halloumi to build the simples possible CloudFormation template... A template defining an empty CloudFormation stack!
For this, we define a Halloumi resource named `Stack`. How such resources are defined is explained in the section "Resource Anatomy".
Compiling this resource into CloudFormation code would give you the following output:

    {
        "AWSTemplateFormatVersion": "2010-09-09",
        "Description": "  "
    }

=end


class Stack < Halloumi::CompoundResource
end
