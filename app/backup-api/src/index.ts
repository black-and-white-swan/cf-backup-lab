interface Env {
  BACKUPS: R2Bucket;
  API_KEY: string;
}

function isAuthorized(request: Request, env: Env): boolean {
  if (!env.API_KEY) return false;
  const encoder = new TextEncoder();
  const expected = encoder.encode(`Bearer ${env.API_KEY}`);
  const received = encoder.encode(request.headers.get("Authorization") ?? "");
  return (
    expected.byteLength === received.byteLength &&
    crypto.subtle.timingSafeEqual(expected, received)
  );
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/health") {
      return Response.json({ status: "ok" });
    }

    const match = url.pathname.match(/^\/backups\/(.+)$/);
    if (!match) {
      return new Response("Not found", { status: 404 });
    }

    if (!isAuthorized(request, env)) {
      return new Response("Unauthorized", { status: 401 });
    }

    const key = match[1];

    switch (request.method) {
      case "PUT": {
        const object = await env.BACKUPS.put(key, await request.arrayBuffer());
        return Response.json(
          { key: object.key, size: object.size, etag: object.etag },
          { status: 201 },
        );
      }
      case "GET": {
        const object = await env.BACKUPS.get(key);
        if (!object) {
          return new Response("Not found", { status: 404 });
        }
        return new Response(object.body, { headers: { etag: object.httpEtag } });
      }
      case "DELETE": {
        try {
          await env.BACKUPS.delete(key);
          return new Response(null, { status: 204 });
        } catch (err) {
          return Response.json({ error: String(err) }, { status: 409 });
        }
      }
      default:
        return new Response("Method not allowed", {
          status: 405,
          headers: { Allow: "GET, PUT, DELETE" },
        });
    }
  },
} satisfies ExportedHandler<Env>;
