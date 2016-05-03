# Author:: Pablo Graubner (graubner@mathematik.uni-marburg.de)
# License:: MIT

require 'minitest/autorun'
require 'yielddb'
require 'dummydb'

class YieldDbTest < Minitest::Test
  def test_star
    helper_morecolumns(1..10) do |i, table|
      query = table.project(Arel.star).to_query
      assert_equal expected(i), query.query
    end
  end

  def test_select_2
    helper_morecolumns(2..10) do |i, table|
      query = table.project(table[:column1], table[:column2]).to_query
      assert_equal expected(i).map {|row| [row[0], row[1]]}, query.query
    end
  end

  def test_select_2_where
    helper_morecolumns(2..10) do |i, table|
      query = table.project(table[:column1], table[:column2]).where(table[:column1].lteq(20).and(table[:column1].gteq(10))).to_query
      results = query.query
      exp = expected(i).map {|row| [row[0], row[1]]}.select do |row|
        val = table.get(:column1, row)
        val <= 20 and val >= 10
      end
      assert_equal exp, results
    end
  end

  def test_aggregators
    helper_morecolumns(2..10) do |i, table|
      query = table.project(table[:column2].count, table[:column2].average, table[:column2].maximum, table[:column2].minimum, table[:column2].sum).to_query
      exp = expected(i).map {|row| row[1]}

      msg= "in: #{i}: #{table.project(Arel.star).to_query.query}"

      assert_equal [10, exp.inject(&:+) / 10, exp.max, exp.min, exp.inject(&:+)], query.query, msg
    end
  end

  def test_order
    helper_morecolumns(2..10) do |i, table|
      query = table.project(table[:column1], table[:column2]).order(table[:column2].desc).to_query

      numbers = expected(i).map {|row| row[1]}.reverse.to_enum
      msg= "in: #{i}: #{table.project(table[:column1], table[:column2]).to_query.query}"

      query.query do |row|
        assert_equal numbers.next, row[1], msg
      end
    end
  end

  def test_join_simple
    helper_morecolumns((2..2),:table1) do |i, table|
      helper_morecolumns((2..2),:table2) do |j, table2|
        predicate = table[:column1].eq( table2[:column1] )
        query = table.join(table2).on( predicate ).to_query

        result = query.query
        msg= "in: #{i}, #{j}, table: #{table.project(Arel.star).to_query.query.inspect}, table2: #{table2.project(Arel.star).to_query.query.inspect}, result: #{result.inspect}"
        assert_equal 10, result.length, msg

        predicate = table[:column1].lteq( table2[:column1] )
        query = table.join(table2).on( predicate ).to_query

        result = query.query
        msg= "in: #{i}, #{j}, table: #{table.project(Arel.star).to_query.query.inspect}, table2: #{table2.project(Arel.star).to_query.query.inspect}, result: #{result.inspect}"
        assert_equal 55, result.length, msg
      end
    end
  end


  def test_join
    helper_morecolumns((2..5),:table1) do |i, table|
      helper_morecolumns((2..5),:table2) do |j, table2|
        predicate = table[:column1].gteq( table2[:column2] )

        query = table.join(table2).on( predicate ).to_query
        result = query.query

        result.each do |row|
          msg= "in: #{i}, #{j}, table: #{table.project(Arel.star).to_query.query}, table2: #{table2.project(Arel.star).to_query.query}"

          assert_equal i+j,row.length, "unexpected row length #{row.length}, #{row} " + msg
          assert row.all? {|v| not v.nil?}, "unexpected nil " + msg
          assert row[0] >= row[i], "unexpected value " + msg
        end
      end
    end
  end

  private
  def expected(i)
    enum = (1..1000).to_enum
    (1..10).map {|_| (1..i).collect {|_| enum.next}}
  end

  def helper_morecolumns(i_s, name = :table)
    (i_s).each do |i|
      table = YieldDb::Table.new(name, Backend::DummyBackend.new(*(1..i).map {|j| "column#{j}".to_sym}))
      assert table.projected_columns.length == i
      yield i, table
    end
  end
end
