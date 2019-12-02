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

  context 'when making a request with a params attribute' do
    it 'returns bad request on create' do
      group = build(:group)
      admin_headers
      post path, build_payload(group, attributes: { params: {} }).to_json
      expect(last_response).to be_bad_request
    end

    it 'returns bad request on update' do
      group = create(:group)
      admin_headers
      patch path(group.fuzzy_id), build_payload(group, attributes: { params: {} }).to_json
      expect(last_response).to be_bad_request
    end
  end

  context 'when making an update request with a priority attribute' do
    it 'can update the priority' do
      group = create(:group)
      new_priority = group.priority + 1
      admin_headers
      patch path(group.fuzzy_id), build_payload(group, attributes: { priority: new_priority }).to_json
      group.reload
      expect(group.priority).to eq(new_priority)
    end
  end

  context 'when creating a group with a cluster by fuzzy id' do
    let(:cluster) { create(:cluster) }
    let(:attributes) { { name: subject.name } }
    let(:payload) do
      build_payload(subject, attributes: attributes, relationships: { cluster: cluster })
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

  context 'when creating a group with nodes by fuzzy id' do
    let(:cluster) { create(:cluster) }
    let(:nodes) do
      (0..10).map { |_| create(:node, cluster: cluster) }
    end
    let(:attributes) { { name: subject.name } }
    let(:payload) do
      rels = { "primary-nodes" => nodes, cluster: cluster }
      build_payload(subject, attributes: attributes, relationships: rels)
    end
    subject { build(:group, cluster: nil) }

    before do
      admin_headers
      post path, payload.to_json
    end

    it 'adds the nodes to the group' do
      group = Group.where(name: subject.name, cluster: cluster).first
      expect(group.primary_nodes).to contain_exactly(*nodes)
    end
  end

  context 'when creating a group without a cluster' do
    let(:payload) { build_payload(subject) }
    subject { build(:group, cluster: nil) }

    before do
      admin_headers
      post path, payload.to_json
    end

    it 'responds unprocessable' do
      expect(last_response).to be_unprocessable
      expect(error_pointers).to include('/data/relationships/cluster')
    end
  end

  shared_context 'with existing group and nodes' do
    let(:cluster) { create(:cluster) }
    let(:old_nodes) { (0..2).map { |_| create(:node, cluster: cluster) } }
    let(:new_nodes) { (0..2).map { |_| create(:node, cluster: cluster) } }
    let(:relationship_path) { path(subject.fuzzy_id, 'relationships', 'primary-nodes') }
    let(:original_nodes) { raise 'original_nodes must be overridden' }
    let(:payload) do
      { data: new_nodes.map { |n| build_rio(n) } }
    end
    subject { create(:group, cluster: cluster, primary_nodes: original_nodes) }
  end

  context 'when adding an additional other nodes to a group' do
    include_context 'with existing group and nodes'

    let(:original_nodes) { old_nodes }

    before do
      admin_headers
      post relationship_path, payload.to_json
      subject.reload
    end

    it 'adds the new node to the existing nodes' do
      expect(subject.primary_nodes).to contain_exactly(*new_nodes, *old_nodes)
    end
  end

  context 'when replacing the nodes within a group' do
    include_context 'with existing group and nodes'

    let(:original_nodes) { old_nodes }

    before do
      admin_headers
      patch relationship_path, payload.to_json
      subject.reload
    end

    it 'only has the new node' do
      expect(subject.nodes).to contain_exactly(*new_nodes)
    end
  end

  context 'when removing nodes from the group' do
    include_context 'with existing group and nodes'

    let(:original_nodes) { [*old_nodes, *new_nodes] }

    before do
      admin_headers
      delete relationship_path, payload.to_json
      subject.reload
    end

    it 'only has the old_nodes' do
      expect(subject.nodes).to contain_exactly(*old_nodes)
    end
  end

  context 'when clearing nodes from a group' do
    include_context 'with existing group and nodes'

    let(:original_nodes) { old_nodes }

    before do
      admin_headers
      patch relationship_path, { data: [] }.to_json
      subject.reload
    end

    it 'has no nodes' do
      expect(subject.nodes).to be_empty
    end
  end
end
