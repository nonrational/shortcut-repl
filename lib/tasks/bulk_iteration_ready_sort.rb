class BulkIterationReadySort
  def run
    iterations.map do |i|
      ok, results = IterationReadySort.new(iteration: i).run
      [i.name, ok, results.count]
    end
  end

  def iterations
    @iterations ||= Iteration.all.reject(&:done?).sort_by(&:start_date)
  end
end
