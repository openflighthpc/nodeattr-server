# API and Routes Documentation

This API broadly conforms the [JSON:API Specifications](https://jsonapi.org/). The major deviation is the each of the `cluster`, `group`, and `node` resource have a "fuzzy__id" in addition to a alphanumeric `id`. The form this "fuzzy_id" takes depends on the section as documented bellow. The `id` and "fuzzy_id" may be used interchangeable but with the following caveats:
1. The `id` is static to the resource (without preforming delete/recreate), and
2. The "fuzzy_id" is not guaranteed to be consistent and may change without notice.

## Clusters

### Fuzzy ID

The "fuzzy id" for a cluster is defined as: `.<cluster-name>` (*NOTE* the leading dot). Modifying the cluster name will naturally lead to the fuzzy id changing.

### List

Return a list of all the clusters:

```
GET /clusters
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Array-Of-Cluster-Objects],
  ... see JSON:API spec ...
}
```

Return all the `nodes`, `groups`, and `cascades` with the cluster:

```
GET /clusters?include=nodes%2Cgroups%2Ccascades
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Array-Of-Cluster-Objects],
  "included": [<Array-Of-Included-Cluster-Node-And-Group-Objects>]
  ... see spec ...
}
```

### Show

Request a single cluster by `id` or "fuzzy-id":

```
GET /clusters/:id_or_fuzzy
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "clusters",
    "id": "<id>",
    "attributes": {
      "name": "<cluster-name>",
      "params": {}
    },
    "relationships": {
      "nodes": { "links": ... see spec ... },
      "groups": { "links": ... see spec ... },
      "cascades": { "links": ... see spec ... }
    },
    "links": ... see spec ...

  }, ... see spec ...
}
```

Include the `nodes`, `groups`, and `cascades` with the request:

```
GET /clusters/:id_or_fuzzy?include=nodes%2Cgroups%2Ccascades
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "clusters",
    "id": "<id>",
    "attributes": {
      "name": "<cluster-name>",
      "params": {}
    },
    "relationships": {
      "nodes": {
        "data": [<Array-Of-Node-Resource-Identifier-Objects>],
        "links": ... see spec ...
      },
      "groups": {
        "data": [<Array-Of-Group-Resource-Identifier-Objects>],
        "links": ... see spec ...
      },
      "cascades": {
        "data": [{<Cluster-Resource-Identifier-Object>}],
        "links": ... see spec ...
      }
    },
    "links": ... see spec ...
  },
  "included": [<Array-Of-Included-Cluster-Object-And-Node-And-Group-Objects>],
  ... see spec ...
}
```

### Create

Create a new cluster resource. The `id` MUST NOT be set with the request. The `level_params` are optional and maybe excluded. The `name` attribute MUST be unique.

```
POST /clusters
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": {
    "type": "clusters",
    "attributes": {
      "name": "<cluster-name>",
      "level_params": {
        "key1": "value1",
        "key2": "value":, ...
      }
    }
  }
}

HTTP/1.1 201 Created
Content-Type: application/vnd.api+json
{
  "data": {<Created-Cluster-Object>},
  ... see spec ...
}
```

An error will be returned if the `name` has already been taken:

```
POST /clusters
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{ ... as above ... }


HTTP/1.1 409 Conflict
Content-Type: application/vnd.api+json
{ ... see error spec ... }
```

### Update

Update an existing `cluster` by `id` or "fuzzy id". The `id`/"fuzzy id" in the request route MUST match the body.

The `level_params` are merged into the existing values instead of doing a replace. This is a deviation from the `JSON:API` specifications. An existing `level_params` keys can be unset by specifically setting them to `null`.

The `name` MAY be changed with this request, but it will result in the "fuzzy id" changing for both itself and any dependent `nodes` and `groups`.

```
PATCH /clusters/:id_or_fuzzy
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": {
    "type": "clusters",
    "id": "<id_or_fuzzy>",
    "attributes": {
      "name": "new-name",
      "level_params": {
        "key1": "new-value",
        "delete-me": null,
        "new-key": "value", ...
      }
    }
  }
}


HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {<Updated-Cluster-Object>},
  ... see spec ...
}
```

An error will be return if the `name` has already been taken:

```
PATCH /clusters/:id_or_fuzzy
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{ ... as above ... }


HTTP/1.1 409 Conflict
Content-Type: application/vnd.api+json
{ ... see error spec ... }
```

### Destroy

Permanently delete a `cluster` by `id` or "fuzzy id":

```
DELETE /clusters/:id_or_fuzzy
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 204 No Content
```

An error will be returned if there are `nodes` or `groups` assigned to the `cluster`. The `pointer` will be either `/data/relationships/nodes` or `/data/relationships/groups` if any `nodes` or `groups` still exist within the cluster respectively. No resource will be deleted as a result of this action.

```
DELETE /clusters/:id_or_fuzzy
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 422 Unprocessable Entity
{
  "errors": [
    {
      "id": "<request-id>",
      "title": "<error-title>",
      "details": "<error-message>",
      "status": "422",
      "source": {
        "pointer": "/data/relationships/<nodes|groups>"
      }
    }
  ]
}
```

### List Nodes Within the Cluster

Return the `nodes` within the `cluster` by `cluster_id` or "fuzzy cluster id". This MAY be combined with the `include` flag.

```
GET /clusters/:cluster_id_or_fuzzy/nodes
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
{
  "data": [<Array-Of-Node-Objects>],
  ... see spec ...
}
```

### List Groups Within the Cluster

Return the `groups` within the `cluster` by `cluster_id` or "fuzzy cluster id". This MAY be combined with the `include` flag.

```
GET /clusters/:id_or_fuzzy/groups
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
{
  "data": [<Array-Of-Group-Objects>],
  ... see spec ...
}
```

### List the Cascades for a Cluster

The `cascades` for a `cluster` is an array of itself. The `params` for a `cluster` are always the same as the `level_params`. The `cascades` can be retrieved by `id` or "fuzzy id".

```
GET /clusters/:id_or_fuzzy/cacades
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [{<Cluster-Object>}],
  ... see spec ...
}
```

## Groups

### Fuzzy ID

The "fuzzy id" for a `group` is defined as: `<cluster-name>.<group-name>` (*NOTE*: the names are delimited by a dot). Modifying the cluster or group name will naturally change the "fuzzy id".

### List

Return all the groups across all clusters:

```
GET /groups
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Array-Of-Group-Objects],
  ... see JSON:API spec ...
}
```

Return all the related `nodes`, `clusters`, and `cascades` within the same request.
*NOTE*: This is not guaranteed to return all the `nodes` and `clusters`. Instead it only returns the resources that have been assigned to at least one `group`.

```
GET /groups?include=nodes%2Ccluster%2Ccascades
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Array-Of-Group-Objects],
  "included": [<Array-Of-Included-Cluster-Node-And-Group-Objects>]
  ... see spec ...
}
```

### Show

Return a specific `group` by `id` or "fuzzy id":

```
GET /groups/:id_or_fuzzy
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "groups",
    "id": "<id>",
    "attributes": {
      "name": "<group-name>",
      "priority": <integer-priority>,
      "params": {}
    },
    "relationships": {
      "nodes": { "links": ... see spec ... },
      "cluster": { "links": ... see spec ... },
      "cascades": { "links": ... see spec ... }
    },
    "links": ... see spec ...

  }, ... see spec ...
}
```

Include the `nodes`, `cluster`, and `cascades` within the same request:

```
GET /groups/:id_or_fuzzy?include=nodes%2Ccluster%2Ccascades
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "groups",
    "id": "<id>",
    "attributes": {
      "name": "<group-name>",
      "priority": <integer-priority>,
      "params": {}
    },
    "relationships": {
      "nodes": {
        "data": [<Array-Of-Node-Resource-Identifier-Objects>],
        "links": ... see spec ...
      },
      "cluster": {
        "data": {<Cluster-Resource-Identifier-Objects>},
        "links": ... see spec ...
      },
      "cascades": {
        "data": [<Array-Of-Cluster-And-Group-Resource-Identifier-Objects>],
        "links": ... see spec ...
      }
    },
    "links": ... see spec ...
  },
  "included": [<Array-Of-Included-Node-Objects-Group-Object-And-Cluster-Object>],
  ... see spec ...
}
```

### Create

Create a new group resource. The `id` MUST NOT be set with the request.

The `name` MUST be set and unique within the corresponding `cluster`. A valid `cluster` resource identifier object MUST be set as a relationship. Additional `node` resource identifier objects MAY be sent as the nodes relationship. The `level_params` are optional and MAY be set with the request. The `priority` MAY be set but MUST be unique within the `cluster`. A valid `priority` will be auto generated by the server if excluded.

```
POST /groups
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": {
    "type": "groups",
    "attributes": {
      "name": "<group-name>",
      "priority": null|"<integer>",
      "level_params": {
        "key1": "value1",
        "key2": "value":, ...
      }
    },
    "relationships": {
      "cluster": {
        "data": {
          "type": 'clusters',
          "id": "<cluster_id_or_fuzzy>"
        }
      },
      "nodes": {
        "data": [
          {
            "type": "nodes",
            "id": "<node_id_or_fuzzy>"
          }, ...
        ]
      }
    }
  }
}

HTTP/1.1 201 Created
Content-Type: application/vnd.api+json
{
  "data": {<Created-Group-Object>},
  ... see spec ...
}
```

An error will be returned if the `name` has already been taken within the `cluster`:

```
POST /groups
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{ ... as above ... }


HTTP/1.1 409 Conflict
Content-Type: application/vnd.api+json
{ ... see error spec ... }
```

An error will be returned if the `cluster` relationship is missing:

```
POST /groups
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": {
    "type": "groups",
    "attributes": {
      "name": "<group-name>"
    }
  }
}


HTTP/1.1 422 Unprocessable Entity
Content-Type: application/vnd.api+json
{
  "errors": [{
    "id": "<request-id>",
    "title": "<error-title>",
    "detail": "<missing-cluster-error-message>",
    "status": 422,
    "source": {
      "pointer": "/data/relationships/cluster"
    }
  }]
}
```

### Update

Update an existing `group` by `id` or "fuzzy id". The `id`/"fuzzy id" must match the request body.

The optional `level_params` attribute will be merged with the existing values instead of doing a direct replacement. An existing `level_params` keys can be unset by specifically setting them to `null`.

The `name` attribute MAY be changed with this request, but it will result in the "fuzzy id" changing.

```
PATCH /groups/:id_or_fuzzy
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": {
    "type": "groups",
    "id": "<id_or_fuzzy>",
    "attributes": {
      "name": "new-name",
      "level_params": {
        "key1": "new-value",
        "delete-me": null,
        "new-key": "value", ...
      }
    }
  }
}

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {<Updated-Group-Object>},
  ... see spec ...
}
```

The `nodes` relationship can be optionally replaced when updating the `group`. This will remove all the existing nodes from the `group` and add the resources specified within the request. Proceed with caution!

```
PATCH /groups/:id_or_fuzzy
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": {
    "type": "groups",
    "id": "<id_or_fuzzy>",
    "relationships": {
      "nodes": {
        "data": [<Array-Of-Node-Resource-Identifier-Objects>]
      }
    }
  }
}

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {<Updated-Group-Object>},
  ... see spec ...
}

```

An error will be return if the `name` has already been taken:

```
PATCH /groups/:id_or_fuzzy
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{ ... as above ... }

HTTP/1.1 409 Conflict
Content-Type: application/vnd.api+json
{ ... see error spec ... }
```

### Destroy

Permanently delete a `group` by `id` or "fuzzy id". The `nodes` are removed from the `group` and will continue to persist after the request has been fulfilled.

```
DELETE /groups/:id_or_fuzzy
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 204 No Content
```

### Show the cluster for a Group

The `cluster` for a `group` can be retrieved directly by `group_id` or "fuzzy group id". This MAY be combined with the `include` flag.

```
GET /groups/:group_id_or_fuzzy/cluster
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {<Cluster-Object>},
  ... see spec ...
}
```

### Undocumented Features: Changing the Cluster for a Group

It is possible to change the `cluster` a group belongs to either on `update` or directly via the `relationships` routes (see specifications). These actions are artefacts of the `create` process and are not formally supported. They MUST fail if the `group` contains ANY `nodes` to prevent them being in separate clusters.

### Show the Nodes in a Group

The `nodes` within the `group` can be retrieved directly by `group_id` or "fuzzy group id". This MAY be combined with the `include` flag.

```
GET /groups/:group_id_or_fuzzy/nodes
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Array-Of-Node-Objects>],
  ... see spec ...
}
```

### Add Nodes to a Group

New `nodes` maybe added to the `group` by `id` or "fuzzy id". The request MAY use a combination of `ids` and "fuzzy ids" within the different objects. Existing `node` memberships within the group will persist after this request.

```
POST /groups/:group_id_or_fuzzy/nodes
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": [
    { "type": "nodes', "id": "<first_node_id_or_fuzzy>" },
    { "type": "nodes", "id": "<second_node_id_or_fuzzy>" },
    ...
  ]
}

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [Array-Of-Node-Resource-Identifier-Objects],
  ... see spec ...
}
```

### Replace Nodes within a Group

The `nodes` within a `group` can be replace by `id` or "fuzzy id". The request MAY use a combination of `ids` and "fuzzy ids" within the different objects. All existing `node` memberships within the group will be removed and replaced by those specified within the request. Proceed with caution!

```
PATCH /groups/:group_id_or_fuzzy/nodes
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": [Array-Of-Node-Resource-Identifier-Objects]
}

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [Array-Of-Node-Resource-Identifier-Objects],
  ... see spec ...
}
```

### Remove Nodes from a Group

A set of `nodes` can be removed from the group by `id` or "fuzzy id". The request MAY use a combination of `ids` and "fuzzy ids" within the different objects. The `nodes` specified within the request will be removed from the `group` if the membership exists; whilst missing memberships are ignored. All other `node` memberships will persist after the request has been fulfilled.

The response contains the resource identifier objects for the remaining `nodes`.

```
DELETE /groups/:group_id_or_fuzzy/nodes
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": [Array-Of-Node-Resource-Identifier-Objects]
}

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [Array-Of-Remaining-Node-Resource-Identifier-Objects],
  ... see spec ...
}
```

### Remove All the Nodes from a Group

All the `nodes` can be removed from a group by `id` or "fuzzy id". This will always remove all the nodes from the `group` and return an empty data set.

```
PATCH /groups/:id_or_fuzzy/nodes
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": []
}

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [],
  ... see spec ...
}
```

### Show the Cascades for a Group

The `cascades` for a `group` dictate the merge order for the `params`. They can be retrieved by `group_id` or "fuzzy group id". The `cascades` is always an array of the `cluster` then the `group`.

```
GET /groups/:group_id_or_fuzzy/cacades
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [
    {<Cluster-Object>},
    {<Group-Object>}
  ],
  ... see spec ...
}
```

## Nodes

### Fuzzy ID

The "fuzzy id" for a `node` is defined as: `<cluster-name>.<node-name>` (*NOTE*: the names are delimited by a dot). Modifying the cluster or node name will naturally change the "fuzzy id".

### List

Return all the `nodes` across all `clusters`:

```
GET /nodes
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Array-Of-Node-Objects],
  ... see JSON:API spec ...
}
```

Return all the related `groups`, `clusters`, and `cascades` within the same request.
*NOTE*: This is not guaranteed to return all the `groups` and `clusters`. Instead it only returns the resources that have been assigned to at least one `node`.

```
GET /nodes?include=groups%2Ccluster%2Ccascades
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Array-Of-Node-Objects],
  "included": [<Array-Of-Included-Group-Node-Object-And-Cluster-Objects>]
  ... see spec ...
}
```

### Show

Return a specific `node` by `id` or "fuzzy id":

```
GET /nodes/:id_or_fuzzy
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "nodes",
    "id": "<id>",
    "attributes": {
      "name": "<node-name>",
      "params": {}
    },
    "relationships": {
      "groups": { "links": ... see spec ... },
      "cluster": { "links": ... see spec ... },
      "cascades": { "links": ... see spec ... }
    },
    "links": ... see spec ...

  }, ... see spec ...
}
```

Include the `groups`,`cluster`, and `cascades` within the same request:

```
GET /nodes/:id_or_fuzzy?include=group%2Ccluster%2Ccascades
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "nodes",
    "id": "<id>",
    "attributes": {
      "name": "<node-name>",
      "params": {}
    },
    "relationships": {
      "nodes": {
        "data": [<Array-Of-Group-Resource-Identifier-Objects>],
        "links": ... see spec ...
      },
      "cluster": {
        "data": {<Cluster-Resource-Identifier-Objects>},
        "links": ... see spec ...
      },
      "cascades:" [
        "data": [<Array-Of-Cluster-Group-Node-Resource-Identifier-Objects>],
        "links": ... see spec ...
      ]
    },
    "links": ... see spec ...
  },
  "included": [<Array-Of-Included-Group-Objects-Node-Object-And-Cluster-Object>],
  ... see spec ...
}
```

### Create

Create a new `node` resource. The `id` MUST NOT be set with the request.

The `name` MUST be set and unique within the corresponding `cluster`. A valid `cluster` resource identifier object MUST be set as a relationship. Additional `group` resource identifier objects MAY be sent as the `groups` relationship. The `level_params` are optional and MAY be set with the request.

```
POST /nodes
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": {
    "type": "nodes",
    "attributes": {
      "name": "<node-name>",
      "level_params": {
        "key1": "value1",
        "key2": "value":, ...
      }
    },
    "relationships": {
      "cluster": {
        "data": {
          "type": 'clusters',
          "id": "<cluster_id_or_fuzzy>"
        }
      },
      "groups": {
        "data": [
          {
            "type": "groups",
            "id": "<group_id_or_fuzzy>"
          }, ...
        ]
      }
    }
  }
}

HTTP/1.1 201 Created
Content-Type: application/vnd.api+json
{
  "data": {<Created-Node-Object>},
  ... see spec ...
}
```

An error will be returned if the `name` has already been taken within the `cluster`:

```
POST /nodes
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{ ... as above ... }

HTTP/1.1 409 Conflict
Content-Type: application/vnd.api+json
{ ... see error spec ... }
```

An error will be returned if the `cluster` relationship is missing:

```
POST /nodes
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": {
    "type": "nodes",
    "attributes": {
      "name": "<node-name>"
    }
  }
}

HTTP/1.1 422 Unprocessable Entity
Content-Type: application/vnd.api+json
{
  "errors": [{
    "id": "<request-id>",
    "title": "<error-title>",
    "detail": "<missing-cluster-error-message>",
    "status": 422,
    "source": {
      "pointer": "/data/relationships/cluster"
    }
  }]
}
```

### Update

Update an existing `node` by `id` or "fuzzy id". The `id`/"fuzzy id" must match the request body.

The optional `level_params` attribute will be merged with the existing values instead of doing a direct replacement. An existing `level_params` keys can be unset by specifically setting them to `null`.

The `name` attribute MAY be changed with this request, but it will result in the "fuzzy id" changing.

```
PATCH /nodes/:id_or_fuzzy
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": {
    "type": "nodes",
    "id": "<id_or_fuzzy>",
    "attributes": {
      "name": "new-name",
      "level_params": {
        "key1": "new-value",
        "delete-me": null,
        "new-key": "value", ...
      }
    }
  }
}

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {<Updated-Nide-Object>},
  ... see spec ...
}
```

An error will be return if the `name` has already been taken:

```
PATCH /nodes/:id_or_fuzzy
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{ ... as above ... }

HTTP/1.1 409 Conflict
Content-Type: application/vnd.api+json
{ ... see error spec ... }
```

### Destroy

Permanently delete a `node` by `id` or "fuzzy id". The `node` is removed from it `groups` before it is deleted.

```
DELETE /groups/:id_or_fuzzy
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 204 No Content
```

### Show the cluster for a Node

The `cluster` for a `node` can be retrieved directly by `node_id` or "fuzzy node id". This MAY be combined with the `include` flag.

```
GET /nodes/:node_id_or_fuzzy/cluster
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {<Cluster-Object>},
  ... see spec ...
}
```

### Undocumented Features: Changing the Cluster for a Node

It is possible to change the `cluster` a node belongs to either on `update` or directly via the `relationships` routes (see specifications). These actions are artefacts of the `create` process and are not formally supported. They MUST fail if the `node` has ANY `group` memberships; to prevent them being in separate clusters.

### List the Groups a Node Belongs To

The `groups` a `node` is a member of can be retrieved directly by `node_id` or "fuzzy node id". This MAY be combined with the `include` flag. The `groups` are always returned in reverse `priority` order.

```
GET /nodes/:node_id_or_fuzzy/groups
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Array-Of-Reverse-Group-Objects>],
  ... see spec ...
}
```

### List the Cascading Objects for a Node

The `cascades` is an array of objects that dictate the `merge` order for the `params`. It always starts with the `cluster`, then it lists the `groups` in reverse `priority` order, before ending with the `node` itself.

```
GET /nodes/:node_id_or_fuzzy/cascades
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [
    {<Cluster-Object>},
    {<Highest-Priority-Group-Object>},
    ...
    {<Lowest-Priority-Group-Object>},
    {<Node-Object>}
  ],
  ... see spec ...
}
```

