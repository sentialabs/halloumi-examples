class BasesShizzle < Halloumi::CompoundResource
  resource :vpcs, type: Halloumi::AWS::EC2::VPC do |r|
    r.property(:cidr_block) { "10.0.0.0/16" }
  end

  resource :subnets, type: Halloumi::AWS::EC2::Subnet, amount: 2 do |r, index|
    r.property(:vpc_id) { vpc.ref }
    r.property(:cidr_block) { "10.0.#{index}.0/24" }
  end
end

class Stack < Halloumi::CompoundResource
  resource :bases, type: BasesShizzle
end
