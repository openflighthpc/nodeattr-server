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

use Sinja::MethodOverride
register Sinja

COMPOUND_ID_REGEX = /\A([[:alnum:]]+)\.([[:alnum:]]+)\Z/

resource :nodes, pkre: /[[:alnum:]]+(?:\.[[:alnum:]]+)?/ do
  helpers do
    def find(id)
      if COMPOUND_ID_REGEX.match?(id)
        matches = COMPOUND_ID_REGEX.match(id).captures
        cluster = Cluster.where(name: matches.first).first
        Node.where(cluster: cluster, name: matches.last).first
      else
        Node.find(id)
      end
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
    node = Node.create(**attr)
    [node.id, node]
  end

  update do |attr|
    resource.update(**attr)
    resource
  end

  destroy { resource.destroy }

  has_one :cluster do
    pluck { resource.cluster }

    graft(sideload_on: :create) do |rio|
      resource.cluster = Cluster.find(rio[:id])
      resource.save
      true
    end
  end

  has_many :group do
    fetch { resource.groups }

    merge(sideload_on: :create) do |rios|
      new_groups = rios.map { |rio| Group.find(rio[:id]) }
      resource.groups << new_groups
      resource.save!
      true
    end

    subtract do |rios|
      ids = rios.map { |rio| rio[:id] }
      resource.groups = resource.groups.reject { |g| ids.include?(g.id.to_s) }
      resource.save!
      true
    end

    replace(sideload_on: :update) do |rios|
      groups = rios.map { |rio| Group.find(rio) }
      resource.groups = groups
      resource.save!
      true
    end

    clear(sideload_on: :update) do
      resource.groups = []
      resource.save
      true
    end
  end
end

GROUP_REGEX = /(?:[\w-]+\.[\w-]+)|(?:\w+)/
resource :groups, pkre: GROUP_REGEX do
  helpers do
    def find(id)
      if id.include?('.')
        cluster_name, group_name = id.split('.', 2)
        cluster = Cluster.where(name: cluster_name).first
        Group.where(cluster: cluster, name: group_name).first
      else
        Group.find(id)
      end
    end
  end

  index do
    Group.all
  end

  show

  create do |attr|
    group = Group.create(**attr)
    [group.id, group]
  end

  # NOTE: Groups Currently can not be updated
  # update do |attr|
  #   resource.update(**attr)
  # end

  destroy { resource.destroy }

  has_one :cluster do
    pluck { resource.cluster }

    graft(sideload_on: :create) do |rio|
      resource.cluster = Cluster.find(rio[:id])
      resource.save!
      true
    end
  end

  has_many :nodes do
    fetch { resource.nodes }
  end
end

cluster_name = /\.[\w-]+/
cluster_id = /[a-zA-Z0-9]+/
resource :clusters, pkre: /#{cluster_name}|#{cluster_id}/ do
  helpers do
    def find(id)
      if id.first == '.'
        Cluster.where(name: id[1..-1]).first
      else
        Cluster.find(id)
      end
    end
  end

  index do
    Cluster.all
  end

  show

  create do |attr|
    cluster = Cluster.create(**attr)
    [cluster.id, cluster]
  end

  update do |attr|
    resource.update(**attr)
    resource
  end

  destroy { resource.destroy }

  has_many :nodes do
    fetch { resource.nodes }
  end
end

