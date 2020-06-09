module Webui
  module Packages
    class FilesController < Packages::MainController
      before_action :set_project
      before_action :set_package
      after_action :verify_authorized

      def new
        authorize @package, :update?
      end

      def update
        authorize @package, :update?

        update_file = FilesManager::UpdateFile.new(@package, params[:filename], params[:file], params[:comment]).call
        if update_file.valid?
          flash.now[:success] = "The file '#{params[:filename]}' has been successfully saved."
          status = 200
        else
          flash.now[:error] = "Error while saving '#{params[:filename]}' file: #{update_file.errors.compact.join("\n")}."
          status = 400
        end

        render layout: false, status: status, partial: 'layouts/webui/flash', object: flash
      end

      def create
        authorize @package, :update?

        upload_file = FilesManager::UploadFiles.new(@package, params[:filename], params[:file], params[:file_url], params[:comment]).call
        if upload_file.valid?
          flash[:success] = "The file '#{params[:filename]}' has been successfully uploaded."
        else
          flash[:error] = "Error while creating '#{params[:filename]}' file: #{upload_file.errors.join("\n")}."
        end

        redirect_to package_show_path(project: @project, package: @package)
      end

      def save_files
        authorize @package, :update?
        filenames = params[:filenames]
        filelist = []

        errors = []

        xml = ::Builder::XmlMarkup.new

        # Iterate over existing files first to keep them in file list
        @package.dir_hash.elements('entry') { |e| xml.entry('name' => e['name'], 'md5' => e['md5'], 'hash' => e['hash']) }
        begin
          # Add new services to _service
          if params[:file_urls].present?
            services = @package.services

            Hash[*params[:file_urls]].try(:each) do |name, url|
              services.addDownloadURL(url, name)
            end

            if services.save
              filelist << '_service'
            else
              errors << 'Failed to add file from URL'
            end
          end
          # Assign names to the uploaded files
          params[:files].try(:each) do |file|
            filenames[file.original_filename] ||= file.original_filename
            filelist << filenames[file.original_filename]
            @package.save_file(rev: 'repository', file: file, filename: filenames[file.original_filename])
            content = File.open(file.path).read if file.is_a?(ActionDispatch::Http::UploadedFile)
            xml.entry('name' => filenames[file.original_filename], 'md5' => Digest::MD5.hexdigest(content), 'hash' => 'sha256:' + Digest::SHA256.hexdigest(content))
          end
          # Create new files from the namelist
          params[:files_new].try(:each) do |new|
            filelist << new
            @package.save_file(rev: 'repository', filename: new)
            xml.entry('name' => new, 'md5' => Digest::MD5.hexdigest(''), 'hash' => 'sha256:' + Digest::SHA256.hexdigest(''))
          end

          if filelist.blank?
            errors << 'No file uploaded, empty file specified or URI given'
          else
            Backend::Api::Sources::Package.write_filelist(@package.project.name, @package.name, "<directory>#{xml.target!}</directory>", user: User.session!.login, comment: params[:comment])
            return if ['_project', '_pattern'].include?(@package.name)

            @package.sources_changed(wait_for_update: ['_aggregate', '_constraints', '_link', '_service', '_patchinfo', '_channel'].any? { |i| filelist.include?(i) })
          end
        rescue APIError => e
          errors << e.message
        rescue Backend::Error => e
          errors << Xmlhash::XMLHash.new(error: e.summary)[:error]
        rescue StandardError => e
          errors << e.message
        end

        if errors.empty?
          message = "'#{filelist}' have been successfully saved."
          redirect_to({ action: :show, project: @project, package: @package }, success: message)
        else
          message = "Error while creating '#{filelist}': #{errors.compact.join("\n")}."
          redirect_back(fallback_location: root_path, error: message)
        end
      end
    end
  end
end
