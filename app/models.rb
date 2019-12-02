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

# This causes destroy! to raise an AcitveModel::ValidationError instead of a
# generic mongoid error. This allows the top level error handling to better
# respond with the exact cause of the error
module HasOverriddenDestroy
  def destroy!(*a, &b)
    destroy(*a, &b)
    errors.any? ? raise(ActiveModel::ValidationError.new(self)) : true
  end
end

module HasLevelParams
  extend ActiveSupport::Concern

  included do
    field :level_params, type: Hash, default: {}
  end

  def level_params=(hash)
    nil_proc = ->(_, v) { v.nil? }
    new_hash = hash.reject(&nil_proc).to_h
    nil_keys = hash.select(&nil_proc).keys

    merged_hash = level_params.merge(new_hash)
    save_hash = nil_keys.each_with_object(merged_hash) do |key, memo|
      memo.delete(key)
    end

    super(save_hash)
  end
end

class Node
  include Mongoid::Document

  include HasFuzzyID
  include HasOverriddenDestroy
  include HasLevelParams

  has_and_belongs_to_many :groups
  belongs_to :cluster

  validates :cluster, presence: true
  validates :name, presence: true, uniqueness: { scope: :cluster }
  validate :validates_groups_cluster

  index({ cluster: 1 })
  index({ cluster: 1, group: 1 })
  index({ name: 1, cluster: 1 }, { unique: true })

  field :name, type: String

  def cascade_params
    cascade_models.reduce({}) { |memo, model| memo.merge(model.level_params) }
  end

  def cascade_models
    [cluster, *groups.sort_by { |g| -g.priority }, self]
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
  include HasOverriddenDestroy
  include HasLevelParams

  has_and_belongs_to_many :nodes
  belongs_to :cluster

  validates :cluster, presence: true
  validates :name, presence: true, uniqueness: { scope: :cluster }
  validates :priority, presence: true, uniqueness: { scope: :cluster }
  validate :validates_nodes_cluster

  index({ cluster: 1 })
  index({ priority: 1 })
  index({ name: 1, cluster: 1 }, { unique: true })
  index({ priority: 1, cluster: 1 }, { unique: true})

  field :name, type: String
  field :priority, type: Integer

  # Set the priority before validated as this ensures the cluster has been set
  before_validation do
    unless priority
      rounded = (self.class.where(cluster: cluster).max(:priority) || 0).round(-2)
      self.priority = rounded + 100
    end
  end

  def cascade_params
    cluster.level_params.merge(level_params)
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

  include HasOverriddenDestroy
  include HasLevelParams

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

  has_many :nodes, dependent: :restrict_with_error
  has_many :groups, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  index({ name: 1 }, { unique: true })

  field :name, type: String

  def cascade_params
    level_params
  end

  def fuzzy_id
    ".#{name}"
  end
end

