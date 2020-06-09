class FilesManager::UploadFiles
  def initialize(package, files, file_urls, new_files, comment)
    @package = package
    @files = files
    @file_urls = file_urls
    @new_files = new_files
    @comment = comment
  end

  def call
    check_file_params
    return self unless valid?

    upload_service_file if @file_urls.present?
    upload_regular_file if @files.present?
    upload_new_file if @new_files.present?

    self
  end

  def errors
    @errors ||= []
  end

  def valid?
    errors.empty?
  end

  def filelist
    @filelist ||= []
  end

  private

  def check_file_params
    errors << 'No file or URI given' unless @files || @file_urls || @new_files
  end

  def upload_service_file
    Hash[*@file_urls].each do |filename, url|
      service_file = FilesManager::UploadRemoteFile.new(@package, url, filename).call
      errors << service_file.errors unless service_file.valid?
      filelist << @filename if service_file.valid?
    end
  end

  def upload_regular_file
    @files.each do |file|
      regular_file = FilesManager::UploadRegularFile.new(@package, file, nil, @comment, 'repository').call
      errors << regular_file.errors unless regular_file.valid?
      filelist << @filename if regular_file.valid?
    end
  end

  def upload_new_file
    @new_files.each do |filename|
      regular_file = FilesManager::UploadRegularFile.new(@package, nil, filename, @comment, 'repository').call
      errors << regular_file.errors unless regular_file.valid?
      filelist << @filename if regular_file.valid?
    end
  end
end
