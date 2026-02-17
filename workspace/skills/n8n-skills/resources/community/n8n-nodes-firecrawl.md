# n8n-nodes-firecrawl

## Basic Information

- Package: `n8n-nodes-firecrawl`
- Category: 🕷️ Web Scraping & Browser Automation
- Version: 0.3.0
- Maintainer: minhlucvan
- npm: [View Package](https://www.npmjs.com/package/n8n-nodes-firecrawl)
- Repository: [View Source](https://github.com/minhlucvan/n8n-nodes-firecrawl)

## Description

FireCrawl nodes for n8n

## Installation

```
n8n-nodes-firecrawl
```

## Nodes (1)

### FireCrawl

- Node Type: `n8n-nodes-firecrawl.fireCrawl`
- Version: 1
- Requires Credentials: Yes

FireCrawl API

#### Available Operations

- **Submit A Crawl Job** (`Submit A Crawl Job`)
  Submits a job to crawl a URL and all accessible subpages
- **Check Crawl Job Status** (`Check Crawl Job Status`)
  Check the status of a crawl job by its ID and retrieve the result
- **Crawl Url With Websocket Monitoring** (`Crawl Url With Websocket Monitoring`)
  Initiate a crawl and monitor progress in real-time using WebSocket
- **Submit A Crawl Job With A Webhook** (`Submit A Crawl Job With A Webhook`)
  Submits a job to crawl a URL and sends webhook events during the crawl process
- **Scrape A Url And Get Its Content** (`Scrape A Url And Get Its Content`)
  Scrape a given URL to retrieve content in markdown, HTML, or other formats. This endpoint supports structured data extraction and dynamic actions.
- **Map A Website And Get Urls** (`Map A Website And Get Urls`)
  Map a URL and retrieve most links present on the website. Optionally, use the `search` parameter to filter URLs by a specific keyword.

#### Core Properties

| Property | Type | Required | Default |
|----------|------|----------|---------|
| `url` | string | Yes | `""` |
| `url` | string | Yes | `""` |
| `crawl_id` | string | Yes | `""` |
| `resource` | hidden | No | `""` |
| `operation` | options | No | `"Submit A Crawl Job"` |
| `url` | string | No | `""` |
| `url` | string | No | `""` |
| `url` | string | No | `"https://firecrawl.dev"` |
| `operation` | notice | No | `""` |
| `operation` | notice | No | `""` |

#### Connection

- Input Types: `main`
- Output Types: `main`

#### Example Configuration

```json
{
  "name": "FireCrawl",
  "type": "n8n-nodes-firecrawl.fireCrawl",
  "typeVersion": 1,
  "position": [
    250,
    300
  ],
  "parameters": {
    "url": "",
    "crawl_id": "",
    "operation": "Submit A Crawl Job"
  }
}
```

---

---

[← Back to Community Nodes Index](README.md)
