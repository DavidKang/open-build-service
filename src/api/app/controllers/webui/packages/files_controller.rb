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

            unless services.save
              errors << "Failed to add file from URL '#{file_url}'"
            end
          elsif filename.present? # No file is provided so we just create an empty new file (touch)
            @package.save_file(filename: filename)
          else
            errors << 'No file or URI given'
          end
        rescue APIError => e
          errors << e.message
        rescue Backend::Error => e
          errors << Xmlhash::XMLHash.new(error: e.summary)[:error]
        rescue StandardError => e
          errors << e.message
        end

        if errors.empty?
          message = "The file '#{filename}' has been successfully saved."
          # We have to check if it's an AJAX request or not
          if request.xhr?
            flash.now[:success] = message
          else
            redirect_to(package_show_path(project: @project, package: @package), success: message)
            return
          end
        else
          message = "Error while creating '#{filename}' file: #{errors.compact.join("\n")}."
          # We have to check if it's an AJAX request or not
          if request.xhr?
            flash.now[:error] = message
            status = 400
          else
            redirect_back(fallback_location: root_path, error: message)
            return
          end
        end

        status ||= 200
        render layout: false, status: status, partial: 'layouts/webui/flash', object: flash
      end
    end
  end
end
