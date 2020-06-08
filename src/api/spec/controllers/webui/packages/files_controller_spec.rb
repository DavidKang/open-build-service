require 'webmock/rspec'
require 'rails_helper'

RSpec.describe Webui::Packages::FilesController, vcr: true do
  let(:user) { create(:confirmed_user, :with_home, login: 'tom') }
  let(:source_project) { user.home_project }
  let(:source_package) { create(:package, name: 'my_package', project: source_project) }

  before do
    login(user)
  end

  describe 'POST #create' do
    let(:expected_success_status) { :found }
    let(:expected_failure_response) { redirect_to(package_show_path(source_project, source_package)) }

    context 'without any uploaded file data' do
      it 'fails with an error message' do
        post :create, params: { project_name: source_project, package_name: source_package }
        expect(response).to expected_failure_response
        expect(flash[:error]).to eq("Error while creating '' file: No file or URI given.")
      end
    end

    context 'with an invalid filename' do
      it 'fails with a backend error message' do
        post :create, params: { project_name: source_project, package_name: source_package, filename: '.test' }
        expect(response).to expected_failure_response
        expect(flash[:error]).to eq("Error while creating '.test' file: '.test' is not a valid filename.")
      end
    end

    context "adding a file that doesn't exist yet" do
      before do
        post :create, params: { project_name: source_project,
                                package_name: source_package,
                                filename: 'newly_created_file',
                                file: 'some_content' }
                  end

      it { expect(response).to have_http_status(expected_success_status) }
      it { expect(flash[:success]).to eq("The file 'newly_created_file' has been successfully uploaded.") }
      it { expect(source_package.source_file('newly_created_file')).to eq('some_content') }
    end

    context 'uploading a utf-8 file' do
      let(:file_to_upload) { File.read(File.expand_path(Rails.root.join('spec/support/files/chinese.txt'))) }

      before do
        post :create, params: { project_name: source_project, package_name: source_package, filename: '学习总结', file: file_to_upload }
      end

      it { expect(response).to have_http_status(expected_success_status) }
      it { expect(flash[:success]).to eq("The file '学习总结' has been successfully uploaded.") }

      it 'creates the file' do
        expect { source_package.source_file('学习总结') }.not_to raise_error
        expect(CGI.escape(source_package.source_file('学习总结'))).to eq(CGI.escape(file_to_upload))
      end
    end

    context 'uploading a file from remote URL' do
      let(:service_content) do
        <<-XML.strip_heredoc.strip
          <services>
            <service name="download_url">
              <param name="host">raw.github.com</param>
              <param name="protocol">https</param>
              <param name="path">/openSUSE/open-build-service/master/.gitignore</param>
              <param name="filename">remote_file</param>
            </service>
          </services>
        XML
      end
      before do
        post :create, params: { project_name: source_project, package_name: source_package, filename: 'remote_file',
                                file_url: 'https://raw.github.com/openSUSE/open-build-service/master/.gitignore' }
      end

      after do
        # Make sure the service only once get's created
        source_package.destroy
      end

      it { expect(response).to have_http_status(expected_success_status) }
      it { expect(flash[:success]).to eq("The file 'remote_file' has been successfully uploaded.") }

      # Uploading a remote file creates a service instead of downloading it directly!
      it 'creates a valid service file' do
        expect { source_package.source_file('_service') }.not_to raise_error
        expect { source_package.source_file('remote_file') }.to raise_error Backend::NotFoundError

        created_service = source_package.source_file('_service')
        expect(created_service).to eq(service_content)
      end
    end
  end

  describe 'PUT #update' do
    let(:package_with_file) { create(:package_with_file, name: 'package_with_files', project: source_project) }


    context 'with valid content' do
      before do
        put :update, params: { project_name: source_project, package_name: package_with_file, filename: 'somefile.txt',
                               file: 'fake content' },
                     xhr: true
      end

      it { expect(response).to have_http_status(200) }
      it { expect(flash[:success]).to eq("The file 'somefile.txt' has been successfully saved.") }
    end

    context 'with an exception' do
      before do
        allow_any_instance_of(Package).to receive(:save_file).and_raise(StandardError, 'fake error')
        put :update, params: { project_name: source_project, package_name: package_with_file, filename: 'somefile.txt',
                               file: 'fake content' },
                     xhr: true
      end

      it { expect(response).to have_http_status(400) }
      it { expect(flash[:error]).to eq("Error while saving 'somefile.txt' file: fake error.") }
    end
  end
end
