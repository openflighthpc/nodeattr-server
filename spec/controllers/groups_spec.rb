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

require 'spec_helper'

RSpec.describe '/groups' do
  def path(*a)
    File.join('/groups', *a)
  end

  describe 'GET show' do
    subject { Group.find_or_create_by(cluster: cluster, name: 'test-group') }

    let!(:cluster) { Cluster.find_or_create_by(name: 'test-group-cluster') }
    let(:subject_named_url) { "/groups/#{cluster.name}.#{subject.name}" }
    let(:subject_id_url) { "/groups/#{subject.id.to_s}" }

    it 'can be found by name' do
      admin_headers
      get subject_named_url
      expect(last_response).to be_ok
      expect(parse_last_response_body.data.id).to eq(subject.id.to_s)
    end

    it 'can be found by id' do
      admin_headers
      get subject_id_url
      expect(last_response).to be_ok
      expect(parse_last_response_body.data.id).to eq(subject.id.to_s)
    end
  end

  context 'when creating a group with a cluster by fuzzy id' do
    let(:cluster) { create(:cluster) }
    let(:payload) do
      build_payload(subject, relationships: { cluster: cluster })
    end
    subject { build(:group, cluster: nil) }

    before do
      admin_headers
      post path, payload.to_json
    end

    it 'creates the group within the cluster' do
      expect(Group.where(name: subject.name, cluster: cluster).first).not_to be_nil
    end
  end
end
