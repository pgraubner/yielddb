module Backend

  class DummyTable < Model::Table

    def initialize(name, *columns)
      super(name, *columns)
    end

    def query_columns(columns)
      enum = (1..1000).to_enum
      if block_given?
        (1..10).each do |_|
          row = generate_row(enum)
          yield columns.map {|c| c.evaluate(@columns, row)}
        end
      else
        (1..10).map do |_|
          generate_row
        end
      end
    end

    def generate_row(enum)
      (1..@columns.length).collect {|_| enum.next}
    end
  end

  class DummyBackend
    attr_reader :type_caster

    def initialize(*column_names)
      @columns = column_names.map {|name| Model::Column.new(self, name)}
      @type_caster = Class.new do
        def type_cast_for_database(attribute_name, value)
          value.to_i
        end
      end.new
    end
    def execute(name)
      DummyTable.new(name, *@columns)
    end
  end
end
