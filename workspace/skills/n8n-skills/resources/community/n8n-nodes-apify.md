# n8n-nodes-apify

## Basic Information

- Package: `n8n-nodes-apify`
- Category: 🔧 Utilities & Tools
- Version: 0.1.0
- Maintainer: minhlucvan
- npm: [View Package](https://www.npmjs.com/package/n8n-nodes-apify)
- Repository: [View Source](https://github.com/minhlucvan/n8n-nodes-apify)

## Description

n8n nodes for Apify

## Installation

```
n8n-nodes-apify
```

## Nodes (1)

### Apify

- Node Type: `n8n-nodes-apify.apify`
- Version: 1
- Requires Credentials: Yes

Apify API

#### Available Operations

- **Get list of actors** (`Get list of actors`)
  Gets the list of all Actors that the user created or used  The response is a list of objects  where each object contains a basic information about a single Actor  To only get Actors created by the user  add the  my 1  query parameter  The endpoint supports pagination using the  limit  and  offset  parameters and it will not return more than 1000 records  By default  the records are sorted by the  createdAt  field in ascending order  therefore you can use pagination to incrementally fetch all Actors while new ones are still being created  To sort the records in descending order  use the  desc 1  parameter
- **Create actor** (`Create actor`)
  Creates a new Actor with settings specified in an Actor object passed as JSON in the POST payload  The response is the full Actor object as returned by the  Get Actor    reference actors actor object get actor  endpoint  The HTTP request must have the  Content Type  application json  HTTP header  The Actor needs to define at least one version of the source code  For more information  see  Version object    reference actors version object   If you want to make your Actor  public  https   docs apify com platform actors publishing  using  isPublic  true   you will need to provide the Actor s  title  and the  categories  under which that Actor will be classified in Apify Store  For this  it s best to use the  constants from our  apify shared js  package  https   github com apify apify shared js blob 2d43ebc41ece9ad31cd6525bd523fb86939bf860 packages consts src consts ts L452 L471
- **Get actor** (`Get actor`)
  Gets an object that contains all the details about a specific Actor
- **Update actor** (`Update actor`)
  Updates settings of an Actor using values specified by an Actor object passed as JSON in the POST payload  If the object does not define a specific property  its value will not be updated  The response is the full Actor object as returned by the  Get Actor    reference actors actor object get actor  endpoint  The request needs to specify the  Content Type  application json  HTTP header  When providing your API authentication token  we recommend using the request s  Authorization  header  rather than the URL    More info    introduction authentication    If you want to make your Actor  public  https   docs apify com platform actors publishing  using  isPublic  true   you will need to provide the Actor s  title  and the  categories  under which that Actor will be classified in Apify Store  For this  it s best to use the  constants from our  apify shared js  package  https   github com apify apify shared js blob 2d43ebc41ece9ad31cd6525bd523fb86939bf860 packages consts src consts ts L452 L471
- **Delete actor** (`Delete actor`)
  Deletes an Actor
- **Get list of runs** (`Get list of runs`)
  Gets the list of runs of a specific actor  The response is a list of objects  where each object contains basic information about a single actor run  The endpoint supports pagination using the  limit  and  offset  parameters and it will not return more than 1000 array elements  By default  the records are sorted by the  startedAt  field in ascending order  therefore you can use pagination to incrementally fetch all records while new ones are still being created  To sort the records in descending order  use  desc 1  parameter  You can also filter runs by status   available statuses  https   docs apify com platform actors running runs and builds lifecycle
- **Run actor** (`Run actor`)
  Runs an Actor and immediately returns without waiting for the run to finish  The POST payload including its  Content Type  header is passed as  INPUT  to the Actor  usually  application json    The Actor is started with the default options  you can override them using various URL query parameters  The response is the Run object as returned by the  Get run    reference actor runs run object and its storages get run  API endpoint  If you want to wait for the run to finish and receive the actual output of the Actor as the response  please use one of the  Run Actor synchronously    reference actors run actor synchronously  API endpoints instead  To fetch the Actor run results that are typically stored in the default dataset  you ll need to pass the ID received in the  defaultDatasetId  field received in the response JSON to the  Get items    reference datasets item collection get items  API endpoint
- **With input** (`With input`)
  Runs a specific Actor and returns its output  The POST payload including its  Content Type  header is passed as  INPUT  to the Actor  usually  code application json  code    The HTTP response contains Actors  OUTPUT  record from its default key value store  The Actor is started with the default options  you can override them using various URL query parameters  If the Actor run exceeds 300     MAX ACTOR JOB SYNC WAIT SECS     seconds  the HTTP response will have status 408  Request Timeout   Beware that it might be impossible to maintain an idle HTTP connection for a long period of time  due to client timeout or network conditions  Make sure your HTTP client is configured to have a long enough connection timeout  If the connection breaks  you will not receive any information about the run and its status  To run the Actor asynchronously  use the  Run Actor    reference actors run collection run actor  API endpoint instead
- **Without input** (`Without input`)
  Runs a specific Actor and returns its output  The run must finish in 300     MAX ACTOR JOB SYNC WAIT SECS     seconds otherwise the API endpoint returns a timeout error  The Actor is not passed any input  Beware that it might be impossible to maintain an idle HTTP connection for a long period of time  due to client timeout or network conditions  Make sure your HTTP client is configured to have a long enough connection timeout  If the connection breaks  you will not receive any information about the run and its status  To run the Actor asynchronously  use the  Run Actor    reference actors run collection run actor  API endpoint instead
- **Run actor synchronously with input and get dataset items** (`Run actor synchronously with input and get dataset items`)
  Runs a specific Actor and returns its dataset items  The POST payload including its  Content Type  header is passed as  INPUT  to the Actor  usually  application json    The HTTP response contains the Actors dataset items  while the format of items depends on specifying dataset items   format  parameter  You can send all the same options in parameters as the  Get Dataset Items    reference datasets item collection get items  API endpoint  The Actor is started with the default options  you can override them using URL query parameters  If the Actor run exceeds 300     MAX ACTOR JOB SYNC WAIT SECS     seconds  the HTTP response will return the 408 status code  Request Timeout   Beware that it might be impossible to maintain an idle HTTP connection for a long period of time  due to client timeout or network conditions  Make sure your HTTP client is configured to have a long enough connection timeout  If the connection breaks  you will not receive any information about the run and its status  To run the Actor asynchronously  use the  Run Actor    reference actors run collection run actor  API endpoint instead
- ... and 6 more operations

#### Core Properties

| Property | Type | Required | Default |
|----------|------|----------|---------|
| `versions` | fixedCollection | Yes | `[]` |
| `actorId` | resourceLocator | Yes | `{"mode":"list","value":""}` |
| `actorId` | resourceLocator | Yes | `{"mode":"list","value":""}` |
| `actorId` | resourceLocator | Yes | `{"mode":"list","value":""}` |
| `actorId` | resourceLocator | Yes | `{"mode":"list","value":""}` |
| `actorId` | resourceLocator | Yes | `{"mode":"list","value":""}` |
| `actorId` | resourceLocator | Yes | `{"mode":"list","value":""}` |
| `actorId` | resourceLocator | Yes | `{"mode":"list","value":""}` |
| `actorId` | resourceLocator | Yes | `{"mode":"list","value":""}` |
| `actorId` | resourceLocator | Yes | `{"mode":"list","value":""}` |

#### Connection

- Input Types: `main`
- Output Types: `main`

#### Example Configuration

```json
{
  "name": "Apify",
  "type": "n8n-nodes-apify.apify",
  "typeVersion": 1,
  "position": [
    250,
    300
  ],
  "parameters": {
    "versions": [],
    "actorId": {
      "mode": "list",
      "value": ""
    },
    "operation": "Get list of actors"
  }
}
```

---

---

[← Back to Community Nodes Index](README.md)
