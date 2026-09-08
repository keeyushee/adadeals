// AdaDeals curator write path.
// Deploy via Supabase Dashboard -> Edge Functions -> Create function "manage-deal"
// (paste this file in, click Deploy) -- no CLI needed.
//
// Requires one secret, set in Dashboard -> Edge Functions -> manage-deal -> Secrets:
//   CURATOR_PASSWORD = <the real curator password>
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically by the platform.

import { createClient } from "npm:@supabase/supabase-js@2";

const CURATOR_PASSWORD = Deno.env.get("CURATOR_PASSWORD") ?? "";
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { password, action, payload } = body ?? {};

  if (!CURATOR_PASSWORD || password !== CURATOR_PASSWORD) {
    return json({ error: "Unauthorized" }, 401);
  }

  try {
    switch (action) {
      case "login": {
        return json({ ok: true });
      }

      case "add": {
        const { data, error } = await supabase.from("deals").insert(payload).select();
        if (error) throw error;
        return json(data);
      }

      case "edit": {
        const { id, fields } = payload ?? {};
        if (!id) return json({ error: "Missing id" }, 400);
        const { data, error } = await supabase.from("deals").update(fields).eq("id", id).select();
        if (error) throw error;
        return json(data);
      }

      case "delete": {
        const { id } = payload ?? {};
        if (!id) return json({ error: "Missing id" }, 400);
        const { error } = await supabase.from("deals").delete().eq("id", id);
        if (error) throw error;
        return json({ ok: true });
      }

      case "unfeature-city": {
        const { city } = payload ?? {};
        if (!city) return json({ error: "Missing city" }, 400);
        const { error } = await supabase
          .from("deals")
          .update({ featured: false })
          .eq("city", city)
          .eq("featured", true);
        if (error) throw error;
        return json({ ok: true });
      }

      default:
        return json({ error: "Unknown action" }, 400);
    }
  } catch (e) {
    return json({ error: String((e as Error)?.message ?? e) }, 500);
  }
});
