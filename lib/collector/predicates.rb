# Author:: Pablo Graubner (graubner@mathematik.uni-marburg.de)
# License:: MIT

module Collector
  class BinaryPredicateIntern < CustomNode.new(Arel::Nodes::Node)
    attr_accessor :left, :right

    def required_columns
      (left.required_columns + right.required_columns).flatten
    end

    def evaluate(columns, row)
      operator = self.class.class_variable_get(:@@operator)
      l= left.evaluate(columns, row)
      r=right.evaluate(columns, row)
      return false if l.nil? or r.nil?
      operator.call(l, r)
    end
  end

  class BinaryPredicate
    def self.new(operator)
      clz = Class.new(BinaryPredicateIntern)
      clz.class_variable_set(:@@operator, operator)
      clz
    end
  end

  class NotEqual < BinaryPredicate.new(Proc.new {|a,b| a!=b}); end
  class Equal < BinaryPredicate.new(Proc.new {|a,b| a==b}); end
  class GreaterThan < BinaryPredicate.new(Proc.new {|a,b| a>b}); end
  class GreaterThanOrEqual < BinaryPredicate.new(Proc.new {|a,b| a>=b}); end
  class LessThan < BinaryPredicate.new(Proc.new {|a,b| a<b}); end
  class LessThanOrEqual < BinaryPredicate.new(Proc.new {|a,b| a<=b}); end
  class Or < BinaryPredicate.new(Proc.new {|a,b| a || b}); end
  class And < BinaryPredicate.new(Proc.new {|a,b| a && b}); end
  class Matches < BinaryPredicate.new(Proc.new {|a,b| a.include?(b)}); end
end
