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

module ModelHelper
  def self.models
    ObjectSpace.each_object(Class).select do |klass|
      klass.included_modules.include? Mongoid::Document
    end
  end
end

class Node
  include Mongoid::Document

  def self.find_by_fuzzy_id(id)
    if id.include? '.'
      cluster_name, name = id.split('.', 2)
      cluster = Cluster.where(name: cluster_name).first
      Node.where(cluster: cluster, name: name).first
    else
      find(id)
    end
  end

  has_and_belongs_to_many :groups
  belongs_to :cluster, optional: true

  validates :name, presence: true, uniqueness: { scope: :cluster }
  validate :validates_groups_cluster

  index({ name: 1, cluster: 1 }, { unique: true })

  field :name, type: String
  field :params, type: Hash, default: {}

  def validates_groups_cluster
    bad_groups = groups.reject { |g| g.cluster == cluster }
    return if bad_groups.empty?
    errors.add :groups_cluster, <<~MSG.squish
      the following groups are not in the same cluster as the node:
      #{bad_groups.map(&:name).join(',')}
    MSG
  end
end

class Group
  include Mongoid::Document

  has_and_belongs_to_many :nodes
  belongs_to :cluster, optional: true

  validates :name, presence: true, uniqueness: { scope: :cluster }
  validate :validates_nodes_cluster

  index({ name: 1, cluster: 1 }, { unique: true })

  field :name, type: String

  def validates_nodes_cluster
    bad_nodes = nodes.reject { |n| n.cluster == cluster }
    return if bad_nodes.empty?
    errors.add :nodes_cluster, <<~MSG.squish
      the following nodes are not in the same cluster as the group:
      #{bad_nodes.map(&:name).join(',')}
    MSG
  end
end

class Cluster
  include Mongoid::Document

  has_many :nodes

  validates :name, presence: true, uniqueness: true

  index({ name: 1 }, { unique: true })

  field :name, type: String
  field :params, type: Hash, default: {}
end

