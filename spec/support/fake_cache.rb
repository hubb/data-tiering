class FakeCache
  def initialize
    @values = {}
  end

  def read(key)
    @values[key]
  end

  def write(key, value)
    @values[key] = value
  end

  def clear
    @values = {}
  end
end
