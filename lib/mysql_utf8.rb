require 'mysql'

class Mysql::Result
  alias each_hash_orig each_hash

  def each_hash
    each_hash_orig do |row|
      if RUBY_VERSION !~ /\b1\.8/
        row.values.each { |v|
          v.force_encoding 'UTF-8' if v.is_a? String
        }
      end
      yield row
    end
  end
end
