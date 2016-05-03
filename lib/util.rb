# Author:: Pablo Graubner (graubner@mathematik.uni-marburg.de)
# License:: MIT

module Util
  class CustomStruct < Struct
    def self.new(*keys)
      s = super
      s.class_eval do
        define_method(:initialize) do |hash|
          hash.each {|k,v| send("#{k}=",v) }
        end
      end
      s
    end
  end
end
