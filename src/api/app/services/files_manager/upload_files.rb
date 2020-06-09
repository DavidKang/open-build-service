class FilesManager::UploadFiles
  def initialize(package, files, file_urls, new_files, comment)
    @package = package
    @files = files
    @file_urls = file_urls
    @new_files = new_files
    @comment = comment
    @xml = ::Builder::XmlMarkup.new
  end

  def call
    check_file_params
    return self unless valid?

    upload_service_file if @file_urls.present?
    upload_file if @files.present?
    upload_new_file if @new_files.present?
    keep_existent_files
    write_to_filelist

    self
  end

  def errors
    @errors ||= []
  end

  def valid?
    errors.empty?
  end

  def list
    @list ||= []
  end

  private

  def check_file_params
    errors << 'No file or URI given' unless @files || @file_urls || @new_files
  end

  def upload_service_file
    Hash[*@file_urls].each do |filename, url|
      service_file = FilesManager::UploadRemoteFile.new(@package, url, filename).call
      errors << service_file.errors unless service_file.valid?
      list << '_service' if service_file.valid?
    end
  end

  def upload_file
    @files.each do |file|
      file = FilesManager::UploadFile.new(@package, file, nil, @comment, 'repository').call
      errors << file.errors unless file.valid?

      if file.valid?
        list << @filename
        content = File.open(file.path).read if file.is_a?(ActionDispatch::Http::UploadedFile)
        add_to_xml(filenames[file.original_filename], content)
      end
    end
  end

  def upload_new_file
    @new_files.each do |filename|
      file = FilesManager::UploadFile.new(@package, nil, filename, @comment, 'repository').call
      errors << file.errors unless file.valid?

      if file.valid?
        list << filename
        add_to_xml(filename)
      end
    end
  end

  def add_to_xml(filename, content = '')
    @xml.entry(name: filename, md5: Digest::MD5.hexdigest(content), hash: "sha256:#{Digest::SHA256.hexdigest(content)}")
  end

  def keep_existent_files
    # Iterate over existing files first to keep them in file list
    @package.dir_hash.elements('entry') { |entry| @xml.entry(name: entry['name'], md5: entry['md5'], hash: entry['hash']) }
  end

  def write_to_filelist
    Backend::Api::Sources::Package.write_filelist(@package.project.name,
                                                  @package.name,
                                                  "<directory>#{@xml.target!}</directory>",
                                                  user: User.session!.login,
                                                  comment: @comment)
    return if ['_project', '_pattern'].include?(@package.name)

    @package.sources_changed(wait_for_update: ['_aggregate', '_constraints', '_link', '_service', '_patchinfo', '_channel'].any? { |i| list.include?(i) })
  end
end
