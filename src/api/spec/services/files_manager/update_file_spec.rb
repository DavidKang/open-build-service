require 'rails_helper'

RSpec.describe FilesManager::UpdateFile do
  let(:user) { create(:confirmed_user, :with_home, login: 'tom') }
  let(:home_project) { user.home_project }
  let(:package_with_file) { create(:package_with_file, name: 'package_with_files', project: home_project) }
  let(:file_content) { 'fake content' }
  let(:comment) { 'adding fake content' }

  describe '#initialize' do
    it { expect { described_class.new(package_with_file, file_content, 'somefile.txt', comment) }.not_to raise_error }
  end

  describe '#call' do
    before do
      User.session = user
    end

    subject { described_class.new(package_with_file, file_content, 'somefile.txt', comment).call }

    context 'with a valid content' do
      before do
        allow(package_with_file).to receive(:save_file).and_return(true)
      end

      it { expect(subject.errors).to be_empty }
      it { expect(subject).to be_valid }
    end

    context 'with an exception' do
      before do
        allow(package_with_file).to receive(:save_file).and_raise(StandardError, 'Fake error')
      end

      it { expect(subject.errors).not_to be_empty }
      it { expect(subject).not_to be_valid }
    end
  end
end
