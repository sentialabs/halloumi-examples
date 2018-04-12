# This example builds a VPC, with 3 public and 3 private
# subnets. Adding NAT for the private subnets is left
# as an exercise for the reader.


# This compiler service requires the name Stack for your
# main resource, normally you would be free to choose
# your own name.
class Stack < Halloumi::CompoundResource


    # Let's build a VPC resource. In Halloumi, we assume
    # that you might want to build multiple instances
    # of a resource, therefore you are required to give
    # your resource a name in plural, like in this case
    # "vpcs".
    resource :vpcs, type: Halloumi::AWS::EC2::VPC do |r|
        # In this code block we can configure the VPC.
        # The VPC resource can be addressed by the
        # variable `r` we specified after the do. As a
        # convention we use `r` as variable name.
        
        # We set the CIDR block property on the VPC
        # resource. The value will be lazily evaluated,
        # that is, the code between the curly brackets
        # will be executed by Ruby at the last possible
        # moment.
        r.property(:cidr_block) { "10.0.0.0/16" }
    end


    # Let's build our private subnets.
    # In this case we will be building 3 subnets, so now
    # it is more natural to use a plural name for the
    # resources. Since we want more than a single subnet,
    # we specify the amount 3.
    # Please note how the various subnets are being
    # named in the resulting CloudFormation Code.
    resource :private_subnets,
             type: Halloumi::AWS::EC2::Subnet,
             amount: 3 do |r, index|
        # In this code block, we have specified the
        # variable `index` next to `r`. This allows us
        # to know which subnet we are configuering. This
        # is useful when setting the `cidr_block` for
        # the subnet.
        
        # We reference the VPC resource from the subnet.
        # The getter `vpc` was created by Halloumi as a
        # shorthand form for `vpcs.first` (which would
        # also work just fine).
        r.property(:vpc_id) { vpc.ref }
        
        # We use the index as part of the CIDR block
        # here. A nicer way would be using the netaddr
        # library to calculate the block based on the
        # VPC's CIDR.
        r.property(:cidr_block) { "10.0.#{index}.0/24" }
        r.property(:availability_zone) do
            {
                'Fn::Select': [
                    index,
                    { 'Fn::GetAZs': "" }
                ]
            }
        end
    end
    
    
    # For our public subnets, we need to build an
    # Internet Gateway. This resource does not require
    # any configuration, so we omit the block.
    resource :internet_gateways,
             type: Halloumi::AWS::EC2::InternetGateway


    # Attaching the Internet Gateway to the VPC, nothing
    # new here...
    resource :vpc_gateway_attachments,
             type: Halloumi::AWS::EC2::VPCGatewayAttachment do |r|
      r.property(:vpc_id) { vpc.ref }
      r.property(:internet_gateway_id) { internet_gateway.ref }
    end
    
    
    # Creating a routing table, nothing new here...
    resource :route_tables, type: Halloumi::AWS::EC2::RouteTable do |r|
      r.property(:vpc_id) { vpc.ref }
    end
    
    
    # Creating a default route for the routing table,
    # nothing new here...
    resource :routes, type: Halloumi::AWS::EC2::Route do |r|
      r.property(:destination_cidr_block) { "0.0.0.0/0" }
      r.property(:gateway_id) { internet_gateway.ref }
      r.property(:route_table_id) { route_table.ref }
    end

    
    # Here we create three subnets that will be made
    # public by attaching the routing table with a
    # default route to the Internet Gateway later.
    resource :public_subnets,
             type: Halloumi::AWS::EC2::Subnet,
             amount: 3 do |r, index|
        r.property(:vpc_id) { vpc.ref }
        
        # We use the index as part of the CIDR block
        # here. A nicer way would be using the netaddr
        # library to calculate the block based on the
        # VPC's CIDR.
        r.property(:cidr_block) { "10.0.#{index+3}.0/24" }
        r.property(:availability_zone) do
            {
                'Fn::Select': [
                    index,
                    { 'Fn::GetAZs': "" }
                ]
            }
        end
    end
    
    
    # For each public subnet we create a routing table
    # association. For the amount here we do something
    # interesting, we provide a lambda function that
    # gets the length of the array containing all the
    # public subnets.
    resource :subnet_route_table_associations,
             type: Halloumi::AWS::EC2::SubnetRouteTableAssociation,
             amount: -> { public_subnets.length } do |r, index|
        r.property(:route_table_id) { route_table.ref }
        
        # Here we reference each individual public
        # subnet by getting it from the array.
        r.property(:subnet_id) { public_subnets[index].ref }
    end
end
