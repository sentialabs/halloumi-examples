=begin

Resource Anatomy: Resources
===========================

The first important thing to know is that Halloumi assumes that when you define a resource, you might want to define multiple instances of the same resource. Therefore all resource naming is required to be done in _plural_, even if you intend to define only a single one!

The resource definition consists of the following elements:

  * The `resource` keyword (which is actually a class method, ed.)
  * The name of the resource (in plural)
  * Keyword arguments (type is compulsory)
  * Code block (optional) for configuring the resource

A resource can have the following keyword arguments:

  * `type` the _class_ defining the resource
  * `amount` the amount of instances desired for this resource, defaults to 1
  * `id` a snake_cased identifier that will be used CamelCased as name in the resulting CloudFormation template (please don't ever use this argument)

Resource types:
  * As a rule of thumb, any CloudFormation resource name prepended by `Halloumi::` should exists.
  * The CloudFormation resource classes are defined in the halloumi-resources library, see for example the [S3 Bucket definition](https://github.com/sentiampc/halloumi-resources/blob/develop/lib/halloumi/resources/aws/s3/bucket.rb).
  * You are free to define your own resources!

The optional code block can be used for configuering the resource, the code block gets called with as aguments the resource object and the index. The resource object can be used to set property and resource values on the resource. The index tells us which resource we are configuering (useful in case we define multiple instances of the same resource).

=end


class Stack < Halloumi::CompoundResource

  # The most simple example, we define a single S3 Bucket.
  # We use the plural name `buckets`.
  # We specify the name as a Ruby symbol (best practice).
  resource :buckets, type: Halloumi::AWS::S3::Bucket
end
