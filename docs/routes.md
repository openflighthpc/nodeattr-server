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

Return all the `nodes` and `groups` with the cluster:

```
GET /clusters?include=nodes%2Cgroups
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Array-Of-Cluster-Objects],
  "included": [<Array-Of-Included-Node-And-Group-Objects>]
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
      "groups": { "links": ... see spec ... }
    },
    "links": ... see spec ...

  }, ... see spec ...
}
```

Include the `nodes` and `groups` with the request:

```
GET /clusters/:id_or_fuzzy?include=nodes%2Cgroups
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
      }
    },
    "links": ... see spec ...
  },
  "included": [<Array-Of-Included-Node-And-Group-Objects>],
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

The following will return the `nodes` within the `cluster` as the `data` instead of `included` resources. Either the `id` or "fuzzy id" maybe used in this request.

```
GET /clusters/:id_or_fuzzy/nodes
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
{
  "data": [<Array-Of-Node-Objects>],
  ... see spec ...
}
```

Include the `groups`, `cluster`, and `cascade` list within the same request:

```
GET /clusters/:id_or_fuzzy/nodes?include=cluster%2Cgroups%2Ccascades
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
{ ... see list node response below ... }
```

### List Groups Within the Cluster

The following will return the `groups` within the `cluster` as the `data` instead of `included` resources. Either the `id` or "fuzzy id" maybe used in this request.

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

Include the `nodes` and `cluster` within the same request:

```
GET /clusters/:id_or_fuzzy/groups?include=cluster%2Cnodes
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
{ ... see list group response below ... }
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

Return all the `nodes` and the `cluster` within the same request:

```
GET /groups?include=nodes%2Ccluster
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Array-Of-Group-Objects],
  "included": [<Array-Of-Included-Node-Objects-And-Cluster-Object>]
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
      "cluster": { "links": ... see spec ... }
    },
    "links": ... see spec ...

  }, ... see spec ...
}
```

Include the `nodes` and `cluster` within the same request:

```
GET /groups/:id_or_fuzzy?include=nodes%2Ccluster
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
      }
    },
    "links": ... see spec ...
  },
  "included": [<Array-Of-Included-Node-Objects-And-Cluster-Object>],
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

The `cluster` the group is contained within can be retrieved directly by `group_id` or "fuzzy group id". This MAY be combined with the `include` flag.

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
