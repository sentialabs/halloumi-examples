# This example builds a VPC, with 3 public and 3 private
# subnets. Adding NAT for the private subnets is left
# as an exercise for the reader.


# This compiler service requires the name Stack for your
# main resource, normally you would be free to choose
# your own name.
class Stack < Halloumi::CompoundResource
    resource :skeletons, type: Halloumi::Skeleton
    
    resource :public_subnet_groups, type: Halloumi::SubnetGroup do  |r|
        r.resource(:skeletons) { skeletons }
        r.property(:service_ip_offset) { 0 }
    end

    resource :private_subnet_groups, type: Halloumi::SubnetGroup do  |r|
        r.resource(:skeletons) { skeletons }
        r.property(:service_ip_offset) { 1 }
        r.property(:private) { true }
    end
end
