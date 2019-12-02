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

RSpec.describe Node do
  context 'when changing clusters with an existing group' do
    let(:cluster) { create(:cluster) }
    let(:group) { create(:group, cluster: cluster) }
    subject { create(:node, cluster: cluster, groups: [group]) }

    before do
      subject.cluster = create(:cluster)
      subject.validate
    end

    it 'is invalid' do
      expect(subject).not_to be_valid
    end
  end

  describe '::find_by_fuzzy_id' do
    subject { create(:node) }
    let!(:fuzzy_id) { "#{subject.cluster.name}.#{subject.name}" }

    it 'can find by id' do
      expect(described_class.find_by_fuzzy_id(subject.id.to_s)).to eq(subject)
    end

    it 'can find by <cluster>.<name>' do
      expect(described_class.find_by_fuzzy_id(fuzzy_id)).to eq(subject)
    end

    it 'returns nil if the node is missing' do
      subject.delete
      expect do
        described_class.find_by_fuzzy_id(fuzzy_id)
      end.to raise_error(Mongoid::Errors::DocumentNotFound)
    end

    it 'returns nil for garbage regular id strings' do
      expect do
        described_class.find_by_fuzzy_id('garbage')
      end.to raise_error(Mongoid::Errors::DocumentNotFound)
    end
  end

  describe '#level_params=' do
    subject { create(:node, level_params: { initial_key => initial_value }) }
    let(:initial_key) { 'initial-key' }
    let(:initial_value) { 'some-initial-value-in-let' }
    let(:key) { 'test-key' }
    let(:value) { 'value-set-in-let' }

    it 'can set a value' do
      subject.level_params = { key => value }
      expect(subject.level_params[key]).to eq(value)
    end

    it 'does not save nil values' do
      subject.level_params = { initial_key => nil }
      expect(subject.level_params.keys).not_to include(initial_key)
    end

    it 'does not alter other keys' do
      subject.level_params = { key => value }
      subject.level_params = { key => nil }
      expect(subject.level_params[initial_key]).to eq(initial_value)
    end

    it 'can set false' do
      subject.level_params = { key => false }
      expect(subject.level_params[key]).to be false
    end
  end

  describe '#cascade_params' do
    def create_group(type, priority)
      idx = keys.find_index(type)
      params = keys[idx..-1].map { |k| [k, "#{type}-#{k}"] }.to_h
      create(:group,
             name: type.to_s,
             cluster: cluster,
             priority: priority,
             level_params: params)
    end

    let(:keys) { [:cluster, :high, :medium, :low, :node] }
    let(:cluster) do
      params = keys.map { |k| [k, "cluster-#{k}"] }.to_h
      create(:cluster, level_params: params)
    end
    let(:high) { create_group(:high, 100) }
    let(:medium) { create_group(:medium, 10) }
    let(:low) { create_group(:low, 1) }

    subject do
      create(:node,
             name: 'node',
             cluster: cluster,
             groups: [medium, high, low],
             level_params: { node: 'node-node' })
    end

    it 'sets each key at the corresponding level' do
      keys.each do |key|
        expect(subject.cascade_params[key]).to eq("#{key}-#{key}")
      end
    end
  end
end

