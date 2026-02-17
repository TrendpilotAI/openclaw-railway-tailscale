# @mendable/n8n-nodes-firecrawl

## Basic Information

- Package: `@mendable/n8n-nodes-firecrawl`
- Category: 🤖 AI & Voice Tools
- Version: 2.0.0
- Maintainer: hello_sideguide
- npm: [View Package](https://www.npmjs.com/package/@mendable/n8n-nodes-firecrawl)
- Repository: [View Source](https://github.com/mendableai/n8n-nodes-firecrawl)

## Description

Official Firecrawl nodes for n8n - scrape, crawl, map, search, and extract data from websites. Supports AI Agent tool usage.

## Installation

```
@mendable/n8n-nodes-firecrawl
```

## Nodes (1)

### Firecrawl

- Node Type: `@mendable/n8n-nodes-firecrawl.firecrawl`
- Version: 1
- Requires Credentials: Yes

Scrape, crawl, map, search, and extract structured data from websites using Firecrawl API

#### Available Operations

- **Scrape a URL and get its content as markdown, summary, or other formats** (`scrape`)
- **Batch scrape multiple URLs simultaneously** (`batchScrape`)
- **Get batch scrape status** (`batchScrapeStatus`)
- **Get batch scrape errors** (`batchScrapeErrors`)
- **Cancel batch scrape job** (`cancelBatchScrape`)

#### Core Properties

| Property | Type | Required | Default |
|----------|------|----------|---------|
| `url` | string | Yes | `"https://firecrawl.dev"` |
| `url` | string | Yes | `"https://firecrawl.dev"` |
| `url` | string | Yes | `"https://firecrawl.dev"` |
| `url` | string | Yes | `"https://firecrawl.dev"` |
| `query` | string | Yes | `""` |
| `urls` | string | Yes | `""` |
| `batchId` | string | Yes | `""` |
| `batchId` | string | Yes | `""` |
| `batchId` | string | Yes | `""` |
| `crawlId` | string | Yes | `""` |

#### Connection

- Input Types: `main`
- Output Types: `main`

#### Example Configuration

```json
{
  "name": "Firecrawl",
  "type": "@mendable/n8n-nodes-firecrawl.firecrawl",
  "typeVersion": 1,
  "position": [
    250,
    300
  ],
  "parameters": {
    "url": "https://firecrawl.dev",
    "query": "",
    "operation": "scrape"
  }
}
```

---

---

[← Back to Community Nodes Index](README.md)
