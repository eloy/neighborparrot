require 'spec_helper'
require 'pp'
describe SendRequestEndPoint do
  let(:err) {|error| Proc.new { |error| fail "API request failed #{error}" } }

  it 'should send messages' do
    test_msg = 'test message'
    app_info = factory_app_info
    post_body = { :channel => 'test',  :data => test_msg }
    signed_body = sign_send_request(post_body, app_info)
    with_api(Router, { :verbose => false, :log_stdout => false}) do
      mongo_db.collection('app_info').insert app_info # Store mongo fixature after start EM
      send_data = { :path => '/send', :body => signed_body }
      req = apost_request(send_data, err)
      req.callback { |http| puts http.response ; schedule_em_stop }
    end
  end

end
