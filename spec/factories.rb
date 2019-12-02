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

FactoryBot.define do
  factory :node do
    cluster
    other_groups { [] }
    sequence(:name) { |n| "factory_bot-node#{n}" }
  end

  factory :group do
    cluster
    other_nodes { [] }
    primary_nodes { [] }
    sequence(:name) { |n| "factory_bot-group#{n}" }

    after(:create) do |group|
      # Ensures that the primary nodes relationship has been updated on the node
      group.primary_nodes.map(&:save)
    end
  end

  factory :cluster do
    sequence(:name) { |n| "factory_bot-cluster#{n}" }
  end
end
