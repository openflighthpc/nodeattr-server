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

module HasFuzzyID
  extend ActiveSupport::Concern

  class_methods do
    def find_by_fuzzy_id(id)
      if id.include? '.'
        cluster_name, name = id.split('.', 2)
        cluster = Cluster.find_by_name(cluster_name)
        where(cluster: cluster, name: name).first.tap do |n|
          next if n
          raise Mongoid::Errors::DocumentNotFound.new(self, cluster: cluster, name: name)
        end
      else
        find(id)
      end
    end
  end

  def fuzzy_id
    "#{cluster.name}.#{name}"
  end
end

class Node
  include Mongoid::Document

  include HasFuzzyID

  has_and_belongs_to_many :groups
  belongs_to :cluster, optional: true

  validates :cluster, presence: true
  validates :name, presence: true, uniqueness: { scope: :cluster }
  validate :validates_groups_cluster

  index({ name: 1, cluster: 1 }, { unique: true })

  field :name, type: String
  field :level_params, type: Hash, default: {}

  def cascade_params
    level_params
  end

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

  include HasFuzzyID

  has_and_belongs_to_many :nodes
  belongs_to :cluster, optional: true

  validates :cluster, presence: true
  validates :name, presence: true, uniqueness: { scope: :cluster }
  validate :validates_nodes_cluster

  index({ name: 1, cluster: 1 }, { unique: true })

  field :name, type: String
  field :level_params, type: Hash, default: {}

  def cascade_params
    level_params
  end

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

  def self.find_by_name(name)
    where(name: name).first.tap do |c|
      next if c
      raise Mongoid::Errors::DocumentNotFound.new(self, name: name)
    end
  end

  def self.find_by_fuzzy_id(id)
    if id.first == '.'
      find_by_name(id[1..-1])
    else
      find(id)
    end
  end

  has_many :nodes
  has_many :groups

  validates :name, presence: true, uniqueness: true

  index({ name: 1 }, { unique: true })

  field :name, type: String
  field :level_params, type: Hash, default: {}

  def cascade_params
    level_params
  end

  def fuzzy_id
    ".#{name}"
  end
end

