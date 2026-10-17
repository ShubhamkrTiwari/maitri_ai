# Maitri AI 🤖💬

**Maitri AI** is a personalized AI companion application built with Flutter, Supabase, pgvector, and Claude API.

---

## Features
- **Custom Avatar Builder**: Customize avatar visual style, hair, outfit, skin/hair colors, voice pitch/speed, and companion personality (`friendly`, `funny`, `calm`, `motivating`, `professional`).
- **Topic Selection**: Choose from preset categories (Career, Fitness, Studies, Tech, Finance, Mental Wellness, Movies, Cooking, Travel) or custom topics. The AI strictly focuses on these topics.
- **Streaming Chat**: Real-time token-by-token streaming responses powered by Claude 3.5 Sonnet via Supabase Edge Functions.
- **Long-Term Memory (pgvector)**: Extract key factual details across sessions, embedded using vector embeddings, and retrieved before each reply.
- **Voice Support**: Speech-to-Text input listening and customizable Text-to-Speech playback.
- **Privacy & Safety**: Row Level Security (RLS) on all database tables, JSON Data Export, Account Deletion, and automated crisis/helpline resource intervention.

---

## Setup Instructions

### 1. Supabase Database Setup
1. Create a project at [supabase.com](https://supabase.com).
2. Navigate to **SQL Editor** in Supabase dashboard.
3. Paste and run the contents of `supabase/migrations/20250101_initial_schema.sql`.

### 2. Supabase Edge Functions Deployment
1. Install Supabase CLI: `npm i -g supabase`
2. Link your project: `supabase link --project-ref your-project-ref`
3. Set secret keys in Supabase dashboard or via CLI:
   ```bash
   supabase secrets set ANTHROPIC_API_KEY="your-claude-api-key"
   supabase secrets set OPENAI_API_KEY="your-openai-api-key"
   ```
4. Deploy edge functions:
   ```bash
   supabase functions deploy chat-stream --no-verify-jwt
   supabase functions deploy extract-memory --no-verify-jwt
   ```

### 3. Flutter App Configuration
1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Update `.env` with your Supabase URL and anon key:
   ```env
   SUPABASE_URL=https://your-supabase-id.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   ```
3. Run the app:
   ```bash
   flutter pub get
   flutter run --dart-define-from-file=.env
   ```
