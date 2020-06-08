class FilesManager::UpdateFile
  attr_reader :package, :filename, :content, :comment

  def initialize(package, filename, content, comment)
    @package = package
    @filename = filename
    @content = content
    @comment = comment
  end

  def call
    begin
      @package.save_file(file: @content, filename: @filename, comment: @comment)
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
end
