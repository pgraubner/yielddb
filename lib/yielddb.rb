# Author:: Pablo Graubner (graubner@mathematik.uni-marburg.de)
# License:: MIT

require 'arel'
require 'util'

require 'collector/customnode'
require 'collector/aggregators'
require 'collector/predicates'
require 'collector/projectors'
require 'collector/union_operators'

require 'model/query'
require 'model/table'

require 'collector/collector'


module Arel
  class TreeManager
    def to_query
      collector = Collector::Collector.new(@ast)
      collector.to_query
    end
  end
  module Attributes
    class Attribute
      def evaluate(row)
        to_column if @column.nil?
        puts @column.table.projected_columns.inspect
        @column.evaluate(@column.table.projected_columns, row)
      end
      def to_column
        @column = Model::Column.new(self.relation, self.name)
      end
    end
  end
end

module YieldDb
  class Table < Arel::Table
    def initialize(name, backend)
      super(name)
      @backend = backend
      @projected_columns = []
      @type_caster = backend.type_caster
    end
    def backend_table
      @backend_table = @backend.execute(@name) if @backend_table.nil?
      @backend_table
    end

    def get(column_name, row)
      row[to_index(column_name)]
    end

    def to_index(column_name)
      cs=projected_columns.select {|c| c.name == column_name}
      raise ArgumentError.new "column #{column_name} not found in #{@projected_columns.inspect}" if cs.empty?
      projected_columns.index(cs.first)
    end

    def projected_columns
      return @projected_columns unless @projected_columns.empty?
      @projected_columns = backend_table.columns

      @projected_columns.each {|c| c.table = self}
      @projected_columns
    end
    alias :required_columns :projected_columns

    def query(columns, &block)
      backend_table.query_columns(columns, &block)
    end

    def inspect
      "#{name}"
    end

    alias :to_s :inspect
  end

end
