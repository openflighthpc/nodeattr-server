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

    it 'returns nil if the cluster is missing' do
      subject.cluster.delete
      expect(described_class.find_by_fuzzy_id(fuzzy_id)).to be_nil
    end

    it 'returns nil if the node is missing' do
      subject.delete
      expect(described_class.find_by_fuzzy_id(fuzzy_id)).to be_nil
    end
  end
end

