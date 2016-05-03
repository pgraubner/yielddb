# Author:: Pablo Graubner (graubner@mathematik.uni-marburg.de)
# License:: MIT

module Collector
  class Aggregator < CustomNode.new(Arel::Nodes::Function)
    attr_accessor :expressions

    def expression
      expressions.first # TODO check if there are other cases
    end

    def required_columns
      expression
    end
  end
  class CountAggregator < Aggregator
    def project(columns, result)
      result.length
    end

    def projected_columns
      [Model::Column.new(expression.table, :count)]
    end
  end

  class MaxAggregator < Aggregator
    def project(columns, result)
      idx = expression.to_index(columns)
      result.map {|row| row[idx]}.max
    end

    def projected_columns
      [Model::Column.new(expression.table, :max)]
    end
  end

  class MinAggregator < Aggregator
    def project(columns, result)
      idx = expression.to_index(columns)
      result.map {|row| row[idx]}.min
    end

    def projected_columns
      [Model::Column.new(expression.table, :min)]
    end
  end

  class SumAggregator < Aggregator
    def project(columns, result)
      idx = expression.to_index(columns)
      result.map {|row| row[idx]}.inject(&:+)
    end

    def projected_columns
      [Model::Column.new(expression.table, :sum)]
    end
  end

  class AvgAggregator < Aggregator
    def project(columns, result)
      idx = expression.to_index(columns)
      sum = result.map {|row| row[idx]}.inject(&:+)
      sum / result.length
    end

    def projected_columns
      [Model::Column.new(expression.table, :avg)]
    end
  end
end
