require 'rails_helper'

RSpec.describe Webui::Users::NotificationsController do
  let(:username) { 'reynoldsm' }
  let!(:user) { create(:confirmed_user, login: username) }
  let!(:other_user) { create(:confirmed_user) }
  let(:state_change_notification) { create(:notification, :state_change, subscriber: user) }
  let(:creation_notification) { create(:notification, :request_created, subscriber: user) }
  let(:review_notification) { create(:notification, :review_wanted, subscriber: user) }
  let(:comment_for_project_notification) { create(:notification, :comment_for_project, subscriber: user) }
  let(:comment_for_package_notification) { create(:notification, :comment_for_package, subscriber: user) }
  let(:comment_for_request_notification) { create(:notification, :comment_for_request, subscriber: user) }
  let(:done_notification) { create(:notification, :state_change, subscriber: user, delivered: true) }
  let(:notifications_for_other_users) { create(:notification, :state_change, subscriber: other_user) }

  shared_examples 'returning success' do
    it 'returns ok status' do
      expect(response.status).to be 200
    end
  end

  before do
    login user_to_log_in
  end

  describe 'GET #index' do
    let(:user_to_log_in) { user }
    let(:default_params) { { user_login: username } }

    subject! do
      get :index, params: params
    end

    context 'when no param type is provided' do
      let(:params) { default_params }

      it_behaves_like 'returning success'

      it 'assigns notifications with all notifications' do
        expect(assigns[:notifications]).to include(state_change_notification,
                                                   creation_notification,
                                                   review_notification,
                                                   comment_for_project_notification,
                                                   comment_for_package_notification,
                                                   comment_for_request_notification)
      end

      it 'does not return the notifications for the other user' do
        expect(assigns[:notifications]).not_to include(notifications_for_other_users)
      end
    end

    context "when param type is 'done'" do
      let(:params) { default_params.merge(type: 'done') }

      it_behaves_like 'returning success'

      it 'sets @notifications to all delivered notifications regardless of type' do
        expect(assigns[:notifications]).to include(done_notification)
      end
    end

    context "when param type is 'reviews'" do
      let(:params) { default_params.merge(type: 'reviews') }

      it_behaves_like 'returning success'

      it "sets @notifications to all undelivered notifications of 'review' type" do
        expect(assigns[:notifications]).to include(review_notification)
      end
    end

    context "when param type is 'comments'" do
      let(:params) { default_params.merge(type: 'comments') }

      it_behaves_like 'returning success'

      it "sets @notifications to all undelivered notifications of 'comments' type" do
        expect(assigns[:notifications]).to include(comment_for_project_notification,
                                                   comment_for_package_notification,
                                                   comment_for_request_notification)
      end
    end

    context "when param type is 'state_changes'" do
      let(:params) { default_params.merge(type: 'state_changes') }

      it_behaves_like 'returning success'

      it "sets @notifications to all undelivered notifications of 'state changes' type" do
        expect(assigns[:notifications]).to include(state_change_notification.reload)
      end
    end

    context 'when user uses user_login param of different user in the path' do
      let(:params) { default_params.merge(user_login: other_user.login) }

      it 'flashes error and redirects to root_path' do
        expect(flash[:error]).to eq("You are not authorized to access the notifications of #{other_user.login}")
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PUT #update' do
    subject! do
      put :update, params: { id: state_change_notification.id, user_login: user_to_log_in.login }
    end

    context 'when the user updates its own notifications' do
      let(:user_to_log_in) { user }

      it 'redirects back' do
        expect(response).to redirect_to(root_path)
      end

      it 'flashes a success message' do
        expect(flash[:success]).to eql('Successfully marked the notification as done')
      end

      it 'sets the notification as delivered' do
        expect(state_change_notification.reload.delivered).to be true
      end
    end

    context "when the user upddates other user's notifications" do
      let(:user_to_log_in) { other_user }

      it 'redirects to the root path' do
        expect(response).to redirect_to(root_path)
      end

      it 'flashes an error message' do
        expect(flash[:error]).to eql('Sorry, you are not authorized to update this Notification::RssFeedItem.')
      end

      it 'does not set the notification as delivered' do
        expect(state_change_notification.reload.delivered).to be false
      end
    end
  end
end
