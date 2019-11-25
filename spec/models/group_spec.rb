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
  context 'without any groups' do
    let(:cluster) { Cluster.find_or_create_by(name: 'test-group') }
    let(:other_cluster) { Cluster.find_or_create_by(name: 'other-test-group') }

    let(:other_node) { Node.find_or_create_by(name: 'test-node', cluster: other_cluster) }

    subject do
      described_class.find_or_create_by(name: 'test-group', cluster: cluster)
    end

    it 'can not have a node in a different group' do
      subject.nodes << other_node
      subject.validate
      expect(subject).not_to be_valid
    end
  end
end
