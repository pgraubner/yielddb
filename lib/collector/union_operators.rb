# Author:: Pablo Graubner (graubner@mathematik.uni-marburg.de)
# License:: MIT

module Collector
  class UnionOperator
    def initialize(right, projections)
      @right = Model::Query.new(right, projections: projections)
    end

    def required_columns
      @right.required_columns
    end

    def projected_columns
      @right.projected_columns
    end

    def evaluate(columns, row)
      @right.query do |row|
        yield row
      end
    end
  end

  class JoinOperator < UnionOperator
    def initialize(right, projections, predicate)
      @right = Model::Query.new(right, projections: projections, wheres: [predicate])
      @projections = projections
      @predicate = predicate
    end

    def evaluate(columns, row)
      predicate = construct_join_predicate(columns, row)
      @right = Model::Query.new(@right.table, projections: @projections, wheres: [predicate])
      @right.query do |row|
        yield row
      end
    end

    private
    def construct_join_predicate(columns, row)
      predicate = @predicate.clone

      if predicate.left.table != @right.table
        predicate.left = Model::Value.new(predicate.left.evaluate(columns, row))
      elsif predicate.right.table != @right.table
        predicate.right = Model::Value.new(predicate.right.evaluate(columns, row))
      end
      predicate
    end
  end
end
