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

RSpec.describe Group do
  context 'when changing a groups cluster with an existing node' do
    let(:cluster) { create(:cluster) }
    let(:node) { create(:node, cluster: cluster) }
    subject { create(:group, cluster: cluster, nodes: [node]) }

    before do
      subject.cluster = create(:cluster)
      subject.validate
    end

    it 'is in valid' do
      expect(subject).not_to be_valid
    end
  end

  describe '#cascade_params' do
    subject { create(:group, cluster: cluster) }
    let(:cluster) { create(:cluster, level_params: { cluster_key => cluster_value }) }
    let(:cluster_key) { 'cluster-key' }
    let(:cluster_value) { 'initial-cluster-value-in-let' }
    let(:cluster_params) { { cluster_key => cluster_value } }
    let(:override_value) { 'new-value' }

    it 'inherits the cluster parameters' do
      expect(subject.cascade_params[cluster_key]).to eq(cluster_value)
    end

    it 'can override the cluster parameter with a level parameter' do
      subject.level_params = { cluster_key => override_value }
      expect(subject.cascade_params[cluster_key]).to eq(override_value)
    end
  end
end
