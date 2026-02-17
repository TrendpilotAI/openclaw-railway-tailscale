/**
 * OpenTelemetry instrumentation for the OpenClaw Railway template.
 *
 * Loaded via `node --import ./src/instrumentation.mjs ./src/server.js`
 * so all auto-instrumentation hooks register before application code runs.
 *
 * Trace backends:
 *   - Langfuse  (LLM tracing + evals)  — requires LANGFUSE_PUBLIC_KEY + LANGFUSE_SECRET_KEY
 *   - Generic OTLP endpoint (optional)  — requires OTEL_EXPORTER_OTLP_ENDPOINT
 *
 * LLM call auto-instrumentation via OpenLLMetry (@traceloop/node-server-sdk)
 * Express/HTTP auto-instrumentation via @opentelemetry/auto-instrumentations-node
 */

import { NodeSDK } from "@opentelemetry/sdk-node";
import { BatchSpanProcessor } from "@opentelemetry/sdk-trace-base";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { getNodeAutoInstrumentations } from "@opentelemetry/auto-instrumentations-node";

// Langfuse OTel integration
let LangfuseSpanProcessor;
try {
  const langfuseOtel = await import("@langfuse/otel");
  LangfuseSpanProcessor = langfuseOtel.LangfuseSpanProcessor;
} catch {
  // @langfuse/otel not available — skip
}

// OpenLLMetry for LLM SDK auto-instrumentation (OpenAI, Anthropic, etc.)
try {
  const traceloop = await import("@traceloop/node-server-sdk");
  traceloop.default.init({
    disableBatch: false,
    instrumentModules: {
      openAI: { enabled: true },
      anthropic: { enabled: true },
      google: { enabled: true },
      cohere: { enabled: true },
    },
  });
} catch {
  // OpenLLMetry not available or init failed — non-fatal
  console.warn("[otel] OpenLLMetry init skipped (missing @traceloop/node-server-sdk or init error)");
}

const spanProcessors = [];

// 1. Langfuse — LLM tracing + evals
const langfusePublicKey = process.env.LANGFUSE_PUBLIC_KEY?.trim();
const langfuseSecretKey = process.env.LANGFUSE_SECRET_KEY?.trim();

if (LangfuseSpanProcessor && langfusePublicKey && langfuseSecretKey) {
  const langfuseProcessor = new LangfuseSpanProcessor({
    publicKey: langfusePublicKey,
    secretKey: langfuseSecretKey,
    baseUrl: process.env.LANGFUSE_BASEURL?.trim() || "https://cloud.langfuse.com",
  });
  spanProcessors.push(langfuseProcessor);
  console.log("[otel] Langfuse span processor enabled");
} else if (langfusePublicKey || langfuseSecretKey) {
  console.warn("[otel] Langfuse: both LANGFUSE_PUBLIC_KEY and LANGFUSE_SECRET_KEY required — skipping");
}

// 2. Generic OTLP exporter (for APM tools like Grafana, Jaeger, etc.)
const otlpEndpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT?.trim();
if (otlpEndpoint) {
  const otlpExporter = new OTLPTraceExporter({ url: `${otlpEndpoint}/v1/traces` });
  spanProcessors.push(new BatchSpanProcessor(otlpExporter));
  console.log(`[otel] OTLP exporter enabled → ${otlpEndpoint}`);
}

// Only start the SDK if at least one backend is configured
if (spanProcessors.length > 0) {
  const sdk = new NodeSDK({
    spanProcessors,
    instrumentations: [
      getNodeAutoInstrumentations({
        // Disable noisy fs instrumentation
        "@opentelemetry/instrumentation-fs": { enabled: false },
        // Disable DNS to reduce noise
        "@opentelemetry/instrumentation-dns": { enabled: false },
      }),
    ],
    serviceName: process.env.OTEL_SERVICE_NAME || "openclaw-railway",
  });

  sdk.start();
  console.log(`[otel] NodeSDK started with ${spanProcessors.length} span processor(s)`);

  // Graceful shutdown
  const shutdown = async () => {
    try {
      await sdk.shutdown();
    } catch {
      // best-effort
    }
  };
  process.on("SIGTERM", shutdown);
  process.on("SIGINT", shutdown);
} else {
  console.log("[otel] No trace backends configured (set LANGFUSE_*_KEY or OTEL_EXPORTER_OTLP_ENDPOINT to enable)");
}
