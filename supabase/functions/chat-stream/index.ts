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

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const token = authHeader?.replace("Bearer ", "") ?? "";
    const { data: { user }, error: userError } = await supabase.auth.getUser(token);

    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const { session_id, message, language = "English" } = body;

    // 1. Fetch user's avatar settings
    const { data: avatar } = await supabase
      .from("avatars")
      .select("*")
      .eq("user_id", user.id)
      .maybeSingle();

    const avatarName = avatar?.name || "Maitri";
    const personality = avatar?.personality || "friendly";

    // 2. Fetch user's topics
    const { data: topicsData } = await supabase
      .from("user_topics")
      .select("custom_topic_name, topic_id")
      .eq("user_id", user.id);

    const selectedTopics = topicsData?.map((t) => t.custom_topic_name || t.topic_id) || [
      "Career",
      "Fitness",
      "Mental wellness",
    ];

    // 3. Retrieve relevant memories (top 5)
    const { data: memories } = await supabase
      .from("memories")
      .select("content")
      .eq("user_id", user.id)
      .limit(5);

    const memoryText = memories?.map((m) => `- ${m.content}`).join("\n") || "No previous memories stored.";

    // 4. Fetch recent messages (last 10)
    const { data: recentMessages } = await supabase
      .from("messages")
      .select("sender, content")
      .eq("session_id", session_id)
      .order("created_at", { ascending: false })
      .limit(10);

    const historyFormatted = (recentMessages || [])
      .reverse()
      .map((m) => `${m.sender === "user" ? "User" : avatarName}: ${m.content}`)
      .join("\n");

    // 5. Build system prompt
    const systemPrompt = `You are ${avatarName}, a ${personality} AI companion of the user.
You ONLY discuss these topics: ${selectedTopics.join(", ")}.
Known memories about the user:
${memoryText}

Recent conversation:
${historyFormatted}

INSTRUCTIONS:
1. ALWAYS reply in the exact language used by the user. If the user speaks in Hindi (Devanagari or Hinglish), respond in Hindi or Hinglish naturally!
2. Current user language preference: ${language}.
3. Stay in character as a ${personality} AI companion.
4. If the user asks about a topic OUTSIDE the allowed topics list (${selectedTopics.join(", ")}), politely decline in their language and suggest adding that topic in Settings/Topic Picker.
5. Mention past memories or details naturally when relevant.`;

    // 6. Call Claude API via streaming SSE
    const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": anthropicApiKey,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-3-5-sonnet-20241022",
        max_tokens: 1024,
        system: systemPrompt,
        messages: [{ role: "user", content: message }],
        stream: true,
      }),
    });

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text();
      return new Response(JSON.stringify({ error: `Claude API Error: ${errText}` }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Stream SSE back to Flutter client
    const transformStream = new TransformStream({
      async transform(chunk, controller) {
        const text = new TextDecoder().decode(chunk);
        const lines = text.split("\n");
        for (const line of lines) {
          if (line.startsWith("data: ")) {
            try {
              const json = JSON.parse(line.substring(6));
              if (json.type === "content_block_delta" && json.delta?.text) {
                controller.enqueue(new TextEncoder().encode(`data: ${json.delta.text}\n\n`));
              }
            } catch (_) {
              // Ignore non-json chunk lines
            }
          }
        }
      },
    });

    return new Response(claudeResponse.body?.pipeThrough(transformStream), {
      headers: {
        ...corsHeaders,
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
      },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
