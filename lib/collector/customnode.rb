# Author:: Pablo Graubner (graubner@mathematik.uni-marburg.de)
# License:: MIT

module Collector
  class CustomNodeIntern
    attr_reader :node

    def to_operand(node)
      o = case node
            when Arel::Attributes::Attribute
              to_column(node)
            when Arel::Nodes::SqlLiteral
              Model::Query.AnyColumn
            when Arel::Nodes::Casted
              c = Casted.new(node)
              c.attribute = to_operand(node.attribute)
              c.value = node.val
              c
            else
              # TODO implement
              raise NotImplementedError.new
          end
      o
    end

    def to_column(node)
      Model::Column.from_node(node)
    end

    def to_number(node)
      node.to_i
    end

    def initialize(node)
      node_klass = self.class.class_variable_get(:@@node_klass)
      unless node.is_a?(node_klass)
        raise ArgumentError.new "wrong node #{node} in #{self}"
      end
      @node = node
    end
  end

  class CustomNode
    def self.new(node_klass)
      clz = Class.new(CustomNodeIntern)

      clz.class_variable_set(:@@node_klass, node_klass)
      clz
    end
  end
end
