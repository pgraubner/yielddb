Gem::Specification.new do |s|
  s.name        = 'yielddb'
  s.version     = '0.1.0'
  s.date        = '2016-05-03'
  s.summary     = "YieldDb"
  s.description = "YieldDb - Yield anything you like and query it like a database."
  s.authors     = ["Pablo Graubner"]
  s.email       = 'graubner@mathematik.uni-marburg.de'
  s.files       = ["lib/yielddb.rb", "lib/util.rb",
    "lib/collector/aggregators.rb",
    "lib/collector/collector.rb",
    "lib/collector/customnode.rb",
    "lib/collector/predicates.rb",
    "lib/collector/projectors.rb",
    "lib/collector/union_operators.rb",
    "lib/model/query.rb",
    "lib/model/table.rb"]
  s.homepage    =
    'http://github.com/pgraubner/yielddb'
  s.license       = 'MIT'
  s.add_runtime_dependency "arel",
    ["~> 7.0"]
  end
