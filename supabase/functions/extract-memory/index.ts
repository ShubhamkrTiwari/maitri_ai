import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY") ?? "";
    const openaiApiKey = Deno.env.get("OPENAI_API_KEY") ?? "";

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const token = authHeader?.replace("Bearer ", "") ?? "";
    const { data: { user }, error: userError } = await supabase.auth.getUser(token);

    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { session_id } = await req.json();

    // 1. Fetch recent messages in session
    const { data: messages } = await supabase
      .from("messages")
      .select("sender, content")
      .eq("session_id", session_id)
      .order("created_at", { ascending: false })
      .limit(10);

    if (!messages || messages.length === 0) {
      return new Response(JSON.stringify({ message: "No messages to extract memory from." }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const conversationText = messages
      .reverse()
      .map((m) => `${m.sender}: ${m.content}`)
      .join("\n");

    // 2. Extract facts using Claude
    const claudeResp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": anthropicApiKey,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-3-5-sonnet-20241022",
        max_tokens: 300,
        messages: [
          {
            role: "user",
            content: `Extract key permanent personal facts (name, goals, preferences, events) about the user from this conversation snippet. Format as a bulleted list of short factual statements. If no new facts, reply with "NONE".\n\nConversation:\n${conversationText}`,
          },
        ],
      }),
    });

    const claudeData = await claudeResp.json();
    const extractedFactsText = claudeData.content?.[0]?.text || "NONE";

    if (extractedFactsText.includes("NONE")) {
      return new Response(JSON.stringify({ message: "No new facts extracted." }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const facts = extractedFactsText
      .split("\n")
      .map((f: string) => f.replace(/^[-*•]\s*/, "").trim())
      .filter((f: string) => f.length > 0);

    // 3. For each fact, create embedding using OpenAI text-embedding-3-small (1536 dim) and store in memories table
    for (const fact of facts) {
      let embedding = null;

      if (openaiApiKey) {
        try {
          const embResp = await fetch("https://api.openai.com/v1/embeddings", {
            method: "POST",
            headers: {
              Authorization: `Bearer ${openaiApiKey}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              model: "text-embedding-3-small",
              input: fact,
            }),
          });
          const embData = await embResp.json();
          embedding = embData.data?.[0]?.embedding;
        } catch (_) {
          // Fallback if embeddings API not available
        }
      }

      await supabase.from("memories").insert({
        user_id: user.id,
        content: fact,
        embedding: embedding,
      });
    }

    return new Response(
      JSON.stringify({ success: true, extracted_count: facts.length, facts }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
