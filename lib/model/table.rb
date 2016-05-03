# Author:: Pablo Graubner (graubner@mathematik.uni-marburg.de)
# License:: MIT

module Model
  class Table
    attr_reader :columns, :name

    def initialize(name, *columns)
      raise ArgumentError.new unless columns.any?
      raise ArgumentError.new unless columns.all? {|c| c.is_a?(Column)}

      @name = name

      @columns=columns
    end

    def query
      result = []
      query_columns(*@columns) do |row|
        if block_given?
          yield row
        else
          result << row
        end
      end
      result
    end

    def query_columns(*columns)
      raise NotImplementedError.new
    end

    def inspect
      "#{@name}"
    end

    alias :to_s :inspect

  end

  class Column
    attr_accessor :table, :name

    def self.from_node node
      Column.new node.relation, node.name
    end

    def initialize table, name
      @table=table
      @name=name
    end

    def ==(other)
      raise ArgumentError if not other.is_a? Column
      table == other.table and name == other.name
    end

    alias :eql? :'=='
    def hash
      table.hash + name.hash
    end

    def to_index(columns)
      columns.index(self)
    end

    def evaluate(columns, row)
      table.type_cast_for_database(self, row[to_index(columns)])
    end

    def cast(value)
      # TODO use column information
      value
    end

    def required_columns
      [self]
    end

    def inspect
      "#{table.inspect}.#{name}"
    end

    alias :to_s :inspect
  end

  class Value
    def initialize(val)
      @val = val
    end

    def required_columns
      []
    end

    def evaluate(columns, row)
      return @val
    end
  end
end
