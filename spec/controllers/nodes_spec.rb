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
# along with Nodeattr Server. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Nodeattr Server, please visit:
# https://github.com/openflighthpc/nodeattr-server
#===============================================================================

require 'spec_helper'

RSpec.describe '/nodes' do
  def path(*a)
    File.join('/nodes', *a)
  end

  context 'when making a request with a params attribute' do
    it 'returns bad request on create' do
      node = build(:node)
      admin_headers
      post path, build_payload(node, attributes: { params: {} }).to_json
      expect(last_response).to be_bad_request
    end

    it 'returns bad request on update' do
      node = create(:node)
      admin_headers
      patch path(node.fuzzy_id), build_payload(node, attributes: { params: {} }).to_json
      expect(last_response).to be_bad_request
    end
  end

  context 'when grafting a cluster by fuzzy id on create' do
    let(:cluster) { create(:cluster) }
    let(:attributes) { { name: subject.name } }
    let(:payload) do
      build_payload(subject, attributes: attributes, relationships: { cluster: cluster })
    end
    subject { build(:node, cluster: nil) }

    before do
      admin_headers
      post path, payload.to_json
    end

    it 'adds the cluster to the node' do
      expect(Node.where(name: subject.name, cluster: cluster).first).not_to be_nil
    end
  end

  context 'when creating a node without a cluster' do
    let(:payload) { build_payload(subject) }
    subject { build(:node, cluster: nil) }

    before do
      admin_headers
      post path, payload.to_json
    end

    it 'responds bad request' do
      expect(last_response).to be_unprocessable
      expect(error_pointers).to include('/data/relationships/cluster')
    end
  end
end

