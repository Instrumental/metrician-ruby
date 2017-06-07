class TestDelayedJob
  def initialize(success: false, failure: false, error: false)
    @success = success
    @failure = failure
    @error = error
  end

  def perform
    return if @success
    raise "bork" if @error
  end
end
