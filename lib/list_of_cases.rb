class ListOfCases

  def load(list_of_cases_file)
    @tsv = load_file_from_disk(list_of_cases_file)
    split_on_newlines
    remove_blank_lines
    remove_comments
    split_on_tabs
    separate_header
    self
  end

  def case_names
    @tsv.map(&:first) # [1..-1] because first line should be titles
  end

  def header
    @header
  end

  def tsv
    @tsv
  end

  private

  def load_file_from_disk(list_of_cases_file)
    # We do the join/split in order to sort out the various mac / windows line endings
    IO.readlines(list_of_cases_file).join
  end

  def split_on_newlines
    @tsv = @tsv.split(/[\n\r]+/)
  end

  def remove_blank_lines
    # Delete empty lines
    @tsv.delete_if { |line| line.strip == "" }
  end

  def remove_comments
    # Delete lines starting with # (which we assume are comments)
    @tsv.delete_if { |line| line.start_with?("#") }
    # Delete lines starting with "# (which we assume are comments, where the user entered # but Excel felt the need to add a quote in front
    @tsv.delete_if { |line| line.start_with?('"#') }
  end

  def split_on_tabs
    # Split the lines on tabs
    @tsv.map! do |line|
      line.split(/\t+/)
    end
  end

  def separate_header
    @header = @tsv.shift
  end

end
