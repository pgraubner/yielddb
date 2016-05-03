# Author:: Pablo Graubner (graubner@mathematik.uni-marburg.de)
# License:: MIT

module Collector

  class Collector
    def initialize(ast)
      @ast = ast
    end
    def to_query
      SelectStatement.new(@ast).to_query
    end
  end

  class SelectStatement < CustomNode.new (Arel::Nodes::SelectStatement)
    def to_ordering(node)
      raise ArgumentError.new "hash ordering not supported" if node.is_a? Hash
      o=Ordering.new(node)
      o.column = to_column(node.value)
      o
    end

    def to_query
      queries = @node.cores.map do |n|
        SelectCore.new(n).to_query
      end
      query = queries.first
      query = Model::UnionQuery.new queries if queries.length > 1

      args = query.args
      args[:limit] = to_number(@node.limit.expr) unless @node.limit.nil?
      unless @node.orders.nil?
        args[:orders] = @node.orders.map {|n| to_ordering(n)}
      end
      args[:offset] = to_number(@node.offset) unless @node.offset.nil?
      query.args = args
      query
    end
  end


  class SelectCore < CustomNode.new (Arel::Nodes::SelectCore)

    def to_union_operator(node, projections)
      case node
        when Arel::Nodes::InnerJoin
          projections = [AnyColumnProjector.new] if projections.empty?
          JoinOperator.new node.left, projections, to_predicate(node.right.expr)
        else
          # TODO implement
          raise NotImplementedError.new
        end
    end

    def to_projection(node)
      p=case node
        when Arel::Nodes::Avg
          AvgAggregator.new(node)
        when Arel::Nodes::Count
          CountAggregator.new(node)
        when Arel::Nodes::Sum
          SumAggregator.new(node)
        when Arel::Nodes::Min
          MinAggregator.new(node)
        when Arel::Nodes::Max
          MaxAggregator.new(node)
        when Arel::Attributes::Attribute
          return ColumnProjector.new(node, to_operand(node))
        when Arel::Nodes::SqlLiteral
          return AnyColumnProjector.new
        when Arel::Nodes::As
          as = Model::Column.new(table: node.left.relation, name: node.right)
          return ColumnProjector.new(node.left, to_operand(node.left), as)
        else
          raise NotImplementedError.new
        end
      p.expressions = node.expressions.map {|e| to_operand(e)}
      p
    end

    def to_comparison(node)
      p = case node
            when Arel::Nodes::NotEqual
              NotEqual.new(node)
            when Arel::Nodes::NotEqual
              NotEqual.new(node)
            when Arel::Nodes::Equality
              Equal.new(node)
            when Arel::Nodes::GreaterThan
              GreaterThan.new(node)
            when Arel::Nodes::GreaterThanOrEqual
              GreaterThanOrEqual.new(node)
            when Arel::Nodes::LessThan
              LessThan.new(node)
            when Arel::Nodes::LessThanOrEqual
              LessThanOrEqual.new(node)
            when Arel::Nodes::Matches
              Matches.new(node)
            else
              puts node.inspect
              # TODO implement
              raise NotImplementedError.new
          end
      # TODO move this to Predicate
      p.left = to_operand(node.left)
      p.right = to_operand(node.right)

      p
    end

    def to_grouping(node)
      p= case node
           when Arel::Nodes::Or
             Or.new(node)
           when Arel::Nodes::And
             And.new(node)
           else
             # TODO implement
             raise NotImplementedError.new
         end
     # TODO move this to Predicate
      p.left = to_predicate(node.left)
      p.right = to_predicate(node.right)

      p
    end

    def to_predicate(node)
      p = case node
            when Arel::Nodes::Grouping
              to_grouping(node.expr)
            when Arel::Nodes::Or, Arel::Nodes::And
              to_grouping(node)
            else
              to_comparison(node)
          end
      p
    end

    def filter_projections(projections, table)
      projections.select {|p|  p.is_a? AnyColumnProjector or p.required_columns.all? {|c|c.table == table}}
    end

    def to_query
      args ={}
      query = Model::Query.new(@node.source.left)

      projections = @node.projections.map { |n| to_projection(n)}
      #args[:projections]=filter_projections(projections, @node.source.left)
      args[:projections]=projections
      args[:projections]=[AnyColumnProjector.new] if projections.empty?

      args[:union_operators]=@node.source.right.map do |n|
        to_union_operator(n, filter_projections(projections, n.left))
      end
      args[:aggregators], args[:projections] = args[:projections].partition {|p| p.is_a? Aggregator}
      args[:wheres]=@node.wheres.map { |n| to_predicate(n)}
      args[:groups]=@node.groups.map { |n| to_column(n)}
      query.args = args
      query
    end
  end


  class Casted < CustomNode.new(Arel::Nodes::Casted)
    attr_accessor :attribute, :value
    def evaluate(columns, row)
      value
    end
    def required_columns
      []
    end
  end

  class Ordering < CustomNode.new(Arel::Nodes::Ordering)
    attr_reader :column

    def column=(column)
      @column = column
    end

    def evaluate(columns, a,b)
      val_a = column.evaluate(columns,a)
      val_b = column.evaluate(columns,b)

      if node.ascending?
        val_a <=> val_b
      else
        val_b <=> val_a
      end
    end
  end



end
