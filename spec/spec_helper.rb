# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Nodeattr Server.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Nodeattr Server is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Cloud. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Nodeattr Server, please visit:
# https://github.com/openflighthpc/nodeattr-server
#===============================================================================

require 'rack/test'
require 'rspec'
require 'rspec/collection_matchers'

ENV['RACK_ENV'] = 'test'

require 'rake'
load File.expand_path('../Rakefile', __dir__)
Rake::Task[:require].invoke

# Purge the existing test db
Mongoid.purge!

require 'json'
require 'hashie'

module RSpecSinatraMixin
  include Rack::Test::Methods
  def app()
    app = Sinatra::Application.new
  end
end

# If you use RSpec 1.x you should use this instead:
RSpec.configure do |c|
	# Include the Sinatra helps into the application
	c.include RSpecSinatraMixin

  def admin_headers
    header 'Content-Type', 'application/vnd.api+json'
    header 'Accept', 'application/vnd.api+json'
    # header 'Authorization', "Bearer #{Token.new(admin: true).generate_jwt}"
  end

  def user_headers
    header 'Content-Type', 'application/vnd.api+json'
    header 'Accept', 'application/vnd.api+json'
    # header 'Authorization', "Bearer #{Token.new(user: true).generate_jwt}"
  end

  def parse_last_request_body
    Hashie::Mash.new(JSON.pase(last_request.body))
  end

  def parse_last_response_body
    Hashie::Mash.new(JSON.parse(last_response.body))
  end
end

RSpec.shared_context 'with_system_path_subject' do
  subject { read_subject }

  def subject_inputs
    ["test-subject_#{described_class.type}"]
  end

  def subject_api_path(*a)
    File.join('/', described_class.type, subject_inputs.join('.'), *a)
  end

  def read_subject
    described_class.read(*subject_inputs)
  end

  def create_subject_and_system_path
    described_class.create(*subject_inputs) do |meta|
      FileUtils.mkdir_p File.dirname(meta.system_path)
      FileUtils.touch meta.system_path
    end
  end

  def expect_forbidden
    expect(last_response.status).to be(403)
  end

  def subject_api_body(payload: nil)
      <<~APIJSON
        {
          "data": {
            "type": "#{described_class.type}",
            "id": "#{subject_inputs.join('.')}",
            "attributes": {
              #{ "\"payload\": \"#{payload}\"" if payload}
            }
          }
        }
      APIJSON
  end
end

