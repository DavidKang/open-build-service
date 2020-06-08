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
    end
  end
end
