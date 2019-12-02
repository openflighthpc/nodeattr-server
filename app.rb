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

require 'sinja/method_override'
require 'hashie'

use Sinja::MethodOverride
register Sinja

COMPOUND_ID_REGEX = /\A([[:alnum:]]+)\.([[:alnum:]]+)\Z/

configure_jsonapi do |c|
  c.conflict_exceptions << Mongoid::Errors::Validations
  c.not_found_exceptions << Mongoid::Errors::DocumentNotFound

  c.validation_exceptions << ActiveModel::ValidationError
  c.validation_formatter = ->(e) do
    relations = e.model.relations.keys.map(&:to_sym)
    e.model.errors.messages.map do |src, msg|
      relations.include?(src) ? [src, msg, 'relationships'] : [src, msg]
    end
  end
end

helpers do
  def updatable_fields
    [:name, :level_params]
  end

  def updatable(**attr)
    raise Sinja::BadRequestError, <<~ERROR.squish if attr.include?(:params)
      The 'params' attribute can not be set directly. Please set the 'level-params' instead!
    ERROR
    updatable_fields.each_with_object({}) do |key, memo|
      memo[key] = attr[key] if attr.key?(key)
    end
  end

  def raise_unless_cluster_relationship(resource)
    raise NoMethodError if data[:relationships][:cluster][:data][:id].nil?
  rescue NoMethodError
    resource.validate!
  end
end

PKRE_REGEX = /(?:[a-zA-Z0-9]+)|(?:[\w-]+\.[\w-]+)/
resource :nodes, pkre: PKRE_REGEX do
  helpers do
    def find(id)
      Node.find_by_fuzzy_id(id)
    end

    def filter(nodes, fields = {})
      nodes.where(name: fields[:nodeattr])
    end
  end

  index(filter_by: :nodeattr) do
    Node.all
  end

  show

  create do |attr|
    node = Node.new(**updatable(attr))
    raise_unless_cluster_relationship(node)
    [node.id, node]
  end

  update do |attr|
    resource.update!(**updatable(attr))
    resource
  end

  destroy { resource.destroy! }

  has_one :cluster do
    pluck { resource.cluster }

    graft(sideload_on: :create) do |rio|
      resource.cluster = Cluster.find_by_fuzzy_id(rio[:id])
      resource.save!
    end
  end

  has_many :other_groups do
    fetch { resource.other_groups }
  end
end

resource :groups, pkre: PKRE_REGEX do
  helpers do
    def find(id)
      Group.find_by_fuzzy_id(id)
    end

    def updatable_fields
      [*super(), :priority]
    end
  end

  index do
    Group.all
  end

  show

  create do |attr|
    group = Group.new(**updatable(**attr))
    raise_unless_cluster_relationship(group)
    [group.id, group]
  end

  update do |attr|
    resource.update!(**updatable(attr))
    resource
  end

  destroy { resource.destroy! }

  has_one :cluster do
    pluck { resource.cluster }

    graft(sideload_on: :create) do |rio|
      resource.cluster = Cluster.find_by_fuzzy_id(rio[:id])
      resource.save!
    end
  end

  [:primary_nodes, :other_nodes].each do |type|
    has_many type do
      fetch { resource.send(type) }

      merge(sideload_on: :create) do |rios|
        defer unless resource.cluster
        resource.send(type) << rios.map { |rio| Node.find_by_fuzzy_id(rio[:id]) }
        resource.save!
      end

      replace do |rios|
        resource.send "#{type}=", rios.map { |rio| Node.find_by_fuzzy_id(rio[:id]) }
        resource.save!
      end

      subtract do |rios|
        remove_nodes = rios.map { |rio| Node.find_by_fuzzy_id(rio[:id]) }
        resource.send "#{type}=", (resource.send(type) - remove_nodes)
        resource.save!
      end

      clear do
        resource.send "#{type}=", []
        resource.save!
      end
    end
  end
end

resource :clusters, pkre: /(?:[a-zA-Z0-9]+)|(?:\.[\w-]+)/ do
  helpers do
    def find(id)
      Cluster.find_by_fuzzy_id(id)
    end
  end

  index do
    Cluster.all
  end

  show

  create do |attr|
    cluster = Cluster.create!(**updatable(attr))
    [cluster.id, cluster]
  end

  update do |attr|
    resource.update!(**updatable(attr))
    resource
  end

  destroy do
    resource.destroy!
  end

  has_many :nodes do
    fetch { resource.nodes }
  end

  has_many :groups do
    fetch { resource.groups }
  end
end

