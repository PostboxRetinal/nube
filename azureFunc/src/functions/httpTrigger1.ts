import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";

type Item = Record<string, unknown> & {
    id: number;
    createdAt: string;
};

const items: Item[] = [];
let nextId = 1;

function json(body: unknown, status = 200): HttpResponseInit {
    return {
        status,
        headers: { "content-type": "application/json" },
        body: JSON.stringify(body),
    };
}

export async function itemsApi(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    const method = request.method.toUpperCase();
    context.log(`${method} ${request.url}`);

    if (method === "GET") {
        return json({ items });
    }

    if (method === "POST") {
        let payload: unknown;

        try {
            payload = await request.json();
        } catch {
            return json({ error: "Expected a valid JSON request body." }, 400);
        }

        if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
            return json({ error: "Expected a JSON object request body." }, 400);
        }

        const item: Item = {
            ...(payload as Record<string, unknown>),
            id: nextId++,
            createdAt: new Date().toISOString(),
        };

        items.push(item);

        return json(item, 201);
    }

    return json({ error: "Method not allowed." }, 405);
}

app.http("items", {
    route: "items",
    methods: ["GET", "POST"],
    authLevel: "anonymous",
    handler: itemsApi,
});
