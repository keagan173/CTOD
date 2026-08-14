import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const json = (body: unknown, status = 410) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json",
      "cache-control": "no-store",
    },
  });

Deno.serve(() => json({ error: "CTOD sandbox bootstrap is permanently closed" }));
