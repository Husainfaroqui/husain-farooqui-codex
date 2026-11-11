# Husain CodeLab — Final platform source

This is the full-stack application source, not a passwordless local demo. It uses Supabase Auth, Postgres and Row Level Security. WhatsApp is used for payment discussion; no online payment gateway is included.

## What is included
- Premium responsive public website and animated portfolio/service interactions.
- Supabase email/password authentication.
- Admin and client roles.
- Admin project creation, editing, deletion, status/progress/deadline management.
- Admin milestone/task management and project update publishing.
- Client-only access to assigned projects, milestones, tasks and updates.
- Database-enforced Row Level Security (RLS).
- WhatsApp project/payment discussion link with prefilled project details.

## Required one-time setup
A live secure service cannot be activated without your own Supabase project credentials.

1. Create a Supabase project.
2. In Supabase SQL Editor, run `supabase/schema.sql`.
3. Copy `.env.example` to `.env`.
4. Fill `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` from Supabase Project Settings → API.
   - Use the publishable/anon key only. NEVER put a service-role key in this frontend.
5. In Supabase Authentication settings, configure the site's local and production redirect URLs.
6. Run `npm install`, then `npm run dev`.
7. Create your owner account through the Workspace signup form.
8. In Supabase → Authentication → Users, copy your user UUID. Run this in SQL Editor:
   `update public.profiles set role='admin' where id='YOUR_AUTH_USER_UUID';`
9. Clients can create accounts through the client signup form. Their profile role is always `client`.
10. To assign a project, copy the client's profile UUID and paste it into the Client user UUID field in the admin project editor.

## Run and build
```bash
npm install
npm run dev
npm run build
```
Deploy the generated `dist/` directory to Cloudflare Pages or another static host. Add the same environment variables to the host's build settings.

## Important production checklist
- Turn on email confirmation and configure SMTP/email templates as appropriate.
- Enable MFA for the owner account.
- Configure Supabase Auth rate limits and allowed redirect URLs.
- Test RLS using separate admin and client accounts before real client data is entered.
- Set the production domain in Supabase Auth redirect allowlist.
- Do not commit `.env`.
- WhatsApp payment link only coordinates payment manually; it does not collect or verify payments.

## Notes
The project showcase cards are concept visuals, not claims of completed client work. Replace them with genuine work before launch. Admin user promotion is deliberately manual and requires access to the Supabase SQL console. No hardcoded shared admin password exists.
