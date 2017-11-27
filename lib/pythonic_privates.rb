module PythonicPrivates
  def method_added(id)
    private id if id.id2name =~ /^_.*[^_]$/
  end
end
