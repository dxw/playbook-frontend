class SearchResult
  attr_reader :doc

  def initialize(data: nil)
    @result = data
    @doc = Document.new(data: @result['document'])
  end

  def context
    @result['context']
  end
end
