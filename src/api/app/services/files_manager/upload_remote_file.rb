class FilesManager::UploadRemoteFile
  def initialize(package, file_url, filename)
    @package = package
    @file_url = file_url
    @filename = filename
  end

  def call
    begin
      services = @package.services
      # detects automatically git://, src.rpm formats
      services.addDownloadURL(@file_url, @filename)
      errors << "Failed to add file from URL '#{@file_url}'" unless services.save
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
