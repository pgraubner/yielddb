# Author:: Pablo Graubner (graubner@mathematik.uni-marburg.de)
# License:: MIT

module Collector
  class Projector < CustomNode.new(Arel::Nodes::Function)
    attr_accessor :expressions
  end

  class ColumnProjector < CustomNode.new(Arel::Attributes::Attribute)
    def initialize(node, column, as=nil)
      super(node)
      @column = column
      @as = as
    end

    def required_columns
      [@column]
    end

    def projected_columns
      [self.as]
    end

    def project(columns, row)
      @column.evaluate(columns, row)
    end

    def as
      @as.nil? ? @column : @as
    end
  end

  class AnyColumnProjector
    def required_columns
      [Model::Query.AnyColumn]
    end

    def project(columns, row)
      row
    end

    def projected_columns
      [Model::Query.AnyColumn]
    end
  end
end

# class CountProjector < Projector
#   def required_columns(query)
#     [Model::AnyColumn.new(table: query)]
#   end
#
#   def project(columns, result)
#     result.length
#   end
#
#   def projected_columns(query)
#     [Model::Column.new(table: query, name: :count)]
#   end
# end


# class AvgProjector < Projector
#   def apply(result)
#     sum=0
#     result.each do |row|
#       sum+= expressions.first.evaluate(row) # TODO multiple columns
#     end
#     result[0] << sum/result.length
#     result[0]
#   end
# end
# class SumProjector < Projector
#   def apply(result)
#     sum=0
#     result.each do |row|
#       sum+= expressions.first.evaluate(row) # TODO multiple columns
#     end
#     result[0] << sum
#     result[0]
#   end
# end
# class MinProjector < Projector
#   def apply(result)
#     min=[]
#     result.each do |row|
#       min << expressions.first.evaluate(row) # TODO multiple columns
#     end
#     result[0] << min.min
#     result[0]
#   end
# end
# class MaxProjector < Projector
#   def apply(result)
#     max=[]
#     result.each do |row|
#       max << expressions.first.evaluate(row) # TODO multiple columns
#     end
#     result[0] << max.max
#     result[0]
#   end
# end
