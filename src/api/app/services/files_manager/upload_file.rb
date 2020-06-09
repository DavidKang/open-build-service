class FilesManager::UploadFile
  def initialize(package, file, filename, comment, rev = nil)
    @package = package
    @file = file
    @filename = filename
    @comment = comment
    @rev = rev
  end

  def call
    begin
      @package.save_file(file_params)
    rescue APIError => e
      errors << e.message
    rescue Backend::Error => e
      errors << Xmlhash::XMLHash.new(error: e.summary)[:error]
    rescue StandardError => e
      errors << e.message
    end

    self
  end

  def errors
    @errors ||= []
  end

  def valid?
    errors.empty?
  end

  private

  def file_params
    return { file: @file, filename: @file.original_filename, comment: @comment } if @file.present? && @filename.empty?

    options = { filename: @filename }
    options.merge!(comment: @comment) unless @rev == 'repository'
    options.merge!(rev: @rev) if @rev
    options.merge!(file: @file) if @file.present?
    options
  end
end
