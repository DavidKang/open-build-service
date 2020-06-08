class FilesManager::UploadFiles
  def initialize(package, filename, file, file_url, comment)
    @package = package
    @filename = filename
    @file = file
    @file_url = file_url
    @comment = comment
  end

  def call
    check_file_params
    return self unless valid?

    if @file_url.present?
      upload_service_file
    else
      upload_regular_file
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

  def check_file_params
    errors << 'No file or URI given' unless @file || @filename || @file_url
  end

  def upload_service_file
    service_file = FilesManager::UploadRemoteFile.new(@package, @file_url, @filename).call
    errors << service_file.errors unless service_file.valid?
  end

  def upload_regular_file
    regular_file = FilesManager::UploadRegularFile.new(@package, @file, @filename, @comment).call
    errors << regular_file.errors unless regular_file.valid?
  end
end
