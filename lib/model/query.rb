# Author:: Pablo Graubner (graubner@mathematik.uni-marburg.de)
# License:: MIT

module Model

  class Query
    attr_reader :table
    attr_accessor :args

    def self.AnyColumn
      '*'
    end

    def initialize(table, **args)
      @table = table
      @args = args
      @required_columns = []
      @projected_columns = []
    end

    def projected_columns
      return @projected_columns unless @projected_columns.empty?

      cs = set_helper(projections + union_operators + aggregators , :projected_columns).to_set
      if cs.include? Query.AnyColumn
        cs -= [Query.AnyColumn]
        cs = @table.projected_columns.to_set + cs
      end
      left_columns,right_columns  = left_right_columns(cs.to_a)

      @projected_columns = left_columns +  right_columns # be aware of order
      @projected_columns
    end

    def required_columns
      return @required_columns unless @required_columns.empty?
      cs = set_helper(projections + union_operators + aggregators + wheres, :required_columns).to_set

      if cs.include? Query.AnyColumn
        cs -= [Query.AnyColumn]
        cs = @table.projected_columns.to_set + cs
      end
      left_columns,right_columns  = left_right_columns(cs.to_a)

      @required_columns = left_columns +  right_columns # be aware of order
      @required_columns
    end

    def wheres
      return [] if @args[:wheres].nil? or @args[:wheres].empty?
      @args[:wheres]
    end

    def projections
      return [] if @args[:projections].nil? or @args[:projections].empty?
      @args[:projections]
    end

    def aggregators
      return [] if @args[:aggregators].nil? or @args[:aggregators].empty?
      @args[:aggregators]
    end

    def orders
      return [] if @args[:orders].nil? or @args[:orders].empty?
      @args[:orders]
    end

    def union_operators
      return [] if @args[:union_operators].nil? or @args[:union_operators].empty?
      @args[:union_operators]
    end


    def query
      result = []

      count = -1
      yield_count = 0

      left_required_columns, _ = left_right_columns(required_columns)

      @table.query(left_required_columns) do |row|
        unless args[:limit].nil?
          break if yield_count >= args[:limit]
        end

        right = []
        unless union_operators.empty?
          #TODO check if this can be done later
          union_operators.map {|jp| jp.evaluate(left_required_columns, row) do |r|
            right << r
          end}
          next if right.empty? # nothing found
        end

        if right.empty?
          rows = [row]
        else
          rows = right.map {|r| row + r}
        end

        rows.each do |row|
          unless wheres.empty?
            next unless wheres.all? {|p| p.evaluate(required_columns, row)}
          end

          count +=1
          unless args[:offset].nil?
            next if count % args[:offset] != 0
          end
          yield_count += 1

          result << row
        end
      end

      if aggregators.any?
        # TODO is this the right behavior?
        result = aggregators.map {|p| p.project(required_columns, result)}
      end

      if projections.any?
        result = result.map do |row|
          row = projections.map do |p|
            p.project(required_columns, row)
          end
          row.flatten
        end
      end

      if orders.any?
        # TODO more than one order
        result.sort! {|a,b| orders.first.evaluate(projected_columns,a,b)}
      end

      if block_given?
        modified = []
        result.each do |row|
          if block_given?
            val = yield row
          end
          modified << val
        end
        result = modified
      end

      result
    end

    def to_h
      Proc.new do |columns, row|
        h = {}
        columns.each do |c|
          h[c.name] = row[c.to_index(columns)]
        end
        h
      end
    end

    protected

    def left_right_columns(columns)
      columns.partition {|c| c.table == @table}
    end

    def set_helper(objects, method, *args)
      cs = objects.map {|p| p.public_send(method, *args)}
      cs.flatten
    end

  end
end
