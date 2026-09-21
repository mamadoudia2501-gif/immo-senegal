-- Immo Sénégal — schéma aligné sur le projet test
-- Projet : immo-senegal-test (zwjsnlcnyqhrtmhdjphb, eu-west-3)
-- URL    : https://zwjsnlcnyqhrtmhdjphb.supabase.co
-- Déjà appliqué sur le projet test via la migration `immo_senegal_core_schema`.
-- Ce fichier sert de référence / nouvel environnement (SQL Editor ou supabase db push).
-- Ne contient aucun secret admin (n° / OTP / clé anon).

begin;

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Profils (1-1 avec auth.users). Rôles : visitor | advertiser | admin
-- Le rôle admin n’est JAMAIS pris depuis le client (metadata).
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  phone text unique not null,
  display_name text,
  role text not null default 'advertiser'
    check (role in ('visitor', 'advertiser', 'admin')),
  whatsapp text,
  other_contact text,
  address text,
  city text,
  free_listings_remaining int not null default 4,
  published_count int not null default 0,
  paid_count int not null default 0,
  story_subscription_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists story_subscription_until timestamptz;

create index if not exists profiles_role_idx on public.profiles (role);

-- ---------------------------------------------------------------------------
-- Annonces. status : active | loue | vendu | supprimee
-- is_active = modération admin (masquer sans changer le cycle de vie)
-- images = jsonb (max 4), bucket storage `listing-images`
-- ---------------------------------------------------------------------------
create table if not exists public.listings (
  id text primary key default gen_random_uuid()::text,
  owner_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  city text not null,
  neighborhood text not null,
  type text not null check (type in ('location', 'vente', 'terrain')),
  kind text not null,
  price_fcfa int not null check (price_fcfa >= 0),
  rooms int,
  surface_m2 int,
  description text not null default '',
  broker_id text,
  publisher_phone text,
  placeholder_hue double precision not null default 160,
  featured boolean not null default false,
  is_active boolean not null default true,
  was_paid boolean not null default false,
  villa_style text,
  listed_at timestamptz not null default now(),
  status text not null default 'active'
    check (status in ('active', 'loue', 'vendu', 'supprimee')),
  images jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint listings_images_max check (jsonb_array_length(images) <= 4)
);

alter table public.listings
  add column if not exists images jsonb not null default '[]'::jsonb;

create index if not exists listings_public_idx
  on public.listings (status, is_active, type, city);
create index if not exists listings_owner_idx on public.listings (owner_id);

-- ---------------------------------------------------------------------------
-- Demandes + chat (`messages` = schéma live, pas chat_messages)
-- ---------------------------------------------------------------------------
create table if not exists public.inquiries (
  id text primary key default gen_random_uuid()::text,
  listing_id text references public.listings (id) on delete set null,
  requester_id uuid references public.profiles (id) on delete set null,
  name text not null,
  phone text not null,
  message text not null,
  status text not null default 'envoyee'
    check (status in ('envoyee', 'enCours', 'traitee')),
  created_at timestamptz not null default now()
);

create index if not exists inquiries_listing_idx on public.inquiries (listing_id);
create index if not exists inquiries_requester_idx on public.inquiries (requester_id);

create table if not exists public.conversations (
  id text primary key default gen_random_uuid()::text,
  inquiry_id text not null unique references public.inquiries (id) on delete cascade,
  listing_id text references public.listings (id) on delete set null,
  listing_title text,
  requester_id uuid references public.profiles (id) on delete set null,
  advertiser_id uuid references public.profiles (id) on delete set null,
  requester_phone text not null,
  requester_name text not null,
  advertiser_phone text,
  created_at timestamptz not null default now()
);

create index if not exists conversations_requester_idx
  on public.conversations (requester_id);
create index if not exists conversations_advertiser_idx
  on public.conversations (advertiser_id);

create table if not exists public.messages (
  id text primary key default gen_random_uuid()::text,
  conversation_id text not null references public.conversations (id) on delete cascade,
  author_id uuid references public.profiles (id) on delete set null,
  author_phone text not null,
  body text not null,
  status text not null default 'sent',
  created_at timestamptz not null default now()
);

create index if not exists messages_conversation_idx
  on public.messages (conversation_id, created_at);

-- ---------------------------------------------------------------------------
-- Stories + file de validation + abonnements
-- ---------------------------------------------------------------------------
create table if not exists public.story_subscriptions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references public.profiles (id) on delete cascade,
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  amount_fcfa int not null default 2000,
  created_at timestamptz not null default now()
);

create table if not exists public.stories (
  id text primary key default gen_random_uuid()::text,
  author_id uuid not null references public.profiles (id) on delete cascade,
  author_phone text not null,
  media_path text not null,
  media_kind text not null default 'image' check (media_kind in ('image', 'video')),
  media_label text,
  media_hue double precision,
  caption text not null default '',
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  expires_at timestamptz not null
);

create index if not exists stories_public_idx
  on public.stories (status, expires_at);
create index if not exists stories_author_idx on public.stories (author_id);

create or replace view public.story_requests as
select
  s.id,
  s.author_id,
  s.author_phone,
  s.media_path,
  s.media_kind,
  s.caption,
  s.status,
  s.created_at,
  s.reviewed_at
from public.stories s
where s.status = 'pending';

-- ---------------------------------------------------------------------------
-- Helpers RLS
-- ---------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

create or replace function public.is_advertiser()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('advertiser', 'admin')
  );
$$;

create or replace function public.has_active_story_subscription()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and story_subscription_until is not null
      and story_subscription_until > now()
  )
  or exists (
    select 1 from public.story_subscriptions
    where profile_id = auth.uid() and ends_at > now()
  );
$$;

-- Nouveau compte Auth → profil (rôle jamais lu depuis user_metadata)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  phone_value text;
begin
  phone_value := coalesce(
    nullif(new.phone, ''),
    nullif(new.raw_user_meta_data->>'phone', ''),
    'pending-' || new.id::text
  );
  insert into public.profiles (id, phone, display_name, role)
  values (
    new.id,
    phone_value,
    coalesce(new.raw_user_meta_data->>'display_name', 'Annonceur'),
    'advertiser'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated
before update on public.profiles
for each row execute function public.touch_updated_at();

drop trigger if exists trg_listings_updated on public.listings;
create trigger trg_listings_updated
before update on public.listings
for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.inquiries enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.story_subscriptions enable row level security;
alter table public.stories enable row level security;

-- Profiles
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles
for select using (
  role <> 'admin'
  or public.is_admin()
  or id = auth.uid()
);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
for update using (id = auth.uid())
with check (id = auth.uid() and role <> 'admin');

drop policy if exists "profiles_admin_all" on public.profiles;
create policy "profiles_admin_all" on public.profiles
for all using (public.is_admin()) with check (public.is_admin());

-- Listings : le public ne lit que active + is_active. Annonceur gère les siennes.
drop policy if exists "listings_public_read" on public.listings;
create policy "listings_public_read" on public.listings
for select using (
  (status = 'active' and is_active = true)
  or owner_id = auth.uid()
  or public.is_admin()
);

drop policy if exists "listings_owner_insert" on public.listings;
create policy "listings_owner_insert" on public.listings
for insert with check (owner_id = auth.uid());

drop policy if exists "listings_owner_update" on public.listings;
create policy "listings_owner_update" on public.listings
for update using (owner_id = auth.uid() or public.is_admin())
with check (owner_id = auth.uid() or public.is_admin());

-- Inquiries : créateur, propriétaire de l’annonce, admin
drop policy if exists "inquiries_select" on public.inquiries;
create policy "inquiries_select" on public.inquiries
for select using (
  requester_id = auth.uid()
  or public.is_admin()
  or exists (
    select 1 from public.listings l
    where l.id = listing_id and l.owner_id = auth.uid()
  )
);

drop policy if exists "inquiries_insert" on public.inquiries;
create policy "inquiries_insert" on public.inquiries
for insert with check (
  requester_id is null or requester_id = auth.uid()
);

-- Conversations + messages : participants uniquement (+ admin lecture)
drop policy if exists "conversations_select" on public.conversations;
create policy "conversations_select" on public.conversations
for select using (
  requester_id = auth.uid()
  or advertiser_id = auth.uid()
  or public.is_admin()
);

drop policy if exists "conversations_insert" on public.conversations;
create policy "conversations_insert" on public.conversations
for insert with check (
  requester_id = auth.uid() or advertiser_id = auth.uid()
);

drop policy if exists "messages_select" on public.messages;
create policy "messages_select" on public.messages
for select using (
  public.is_admin()
  or exists (
    select 1 from public.conversations c
    where c.id = conversation_id
      and (c.requester_id = auth.uid() or c.advertiser_id = auth.uid())
  )
);

drop policy if exists "messages_insert" on public.messages;
create policy "messages_insert" on public.messages
for insert with check (
  exists (
    select 1 from public.conversations c
    where c.id = conversation_id
      and (c.requester_id = auth.uid() or c.advertiser_id = auth.uid())
  )
  and (author_id is null or author_id = auth.uid())
);

-- Abonnements stories
drop policy if exists "story_subs_select" on public.story_subscriptions;
create policy "story_subs_select" on public.story_subscriptions
for select using (profile_id = auth.uid() or public.is_admin());

drop policy if exists "story_subs_insert" on public.story_subscriptions;
create policy "story_subs_insert" on public.story_subscriptions
for insert with check (profile_id = auth.uid());

drop policy if exists "story_subs_update" on public.story_subscriptions;
create policy "story_subs_update" on public.story_subscriptions
for update using (profile_id = auth.uid() or public.is_admin());

-- Stories : public = validées et non expirées
drop policy if exists "stories_public_read" on public.stories;
create policy "stories_public_read" on public.stories
for select using (
  (status = 'approved' and expires_at > now())
  or author_id = auth.uid()
  or public.is_admin()
);

drop policy if exists "stories_insert" on public.stories;
create policy "stories_insert" on public.stories
for insert with check (
  author_id = auth.uid()
  and public.has_active_story_subscription()
  and status = 'pending'
);

drop policy if exists "stories_admin_update" on public.stories;
create policy "stories_admin_update" on public.stories
for update using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
grant usage on schema public to anon, authenticated;

grant select on table public.profiles to anon, authenticated;
grant update on table public.profiles to authenticated;

grant select on table public.listings to anon, authenticated;
grant insert, update on table public.listings to authenticated;

grant select, insert on table public.inquiries to authenticated;
grant select, insert on table public.conversations to authenticated;
grant select, insert on table public.messages to authenticated;

grant select, insert, update on table public.story_subscriptions to authenticated;
grant select on table public.stories to anon, authenticated;
grant insert, update on table public.stories to authenticated;
grant select on public.story_requests to authenticated;

-- ---------------------------------------------------------------------------
-- Storage buckets (images annonces max 4 côté table ; stories image/vidéo)
-- Bucket live : listing-images + story-media
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'listing-images',
    'listing-images',
    true,
    5242880,
    array['image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'story-media',
    'story-media',
    true,
    20971520,
    array['image/jpeg', 'image/png', 'image/webp', 'video/mp4']
  )
on conflict (id) do nothing;

drop policy if exists "listing_images_public_read" on storage.objects;
create policy "listing_images_public_read"
on storage.objects for select
using (bucket_id = 'listing-images');

drop policy if exists "listing_images_owner_write" on storage.objects;
create policy "listing_images_owner_write"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'listing-images'
  and split_part(name, '/', 1) = auth.uid()::text
);

drop policy if exists "listing_images_owner_delete" on storage.objects;
create policy "listing_images_owner_delete"
on storage.objects for delete to authenticated
using (
  bucket_id = 'listing-images'
  and split_part(name, '/', 1) = auth.uid()::text
);

drop policy if exists "story_media_public_read" on storage.objects;
create policy "story_media_public_read"
on storage.objects for select
using (bucket_id = 'story-media');

drop policy if exists "story_media_owner_write" on storage.objects;
create policy "story_media_owner_write"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'story-media'
  and split_part(name, '/', 1) = auth.uid()::text
);

-- Realtime chat
do $$
begin
  execute 'alter publication supabase_realtime add table public.messages';
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

commit;

-- ---------------------------------------------------------------------------
-- Promotion admin (à exécuter APRÈS création du compte dans Authentication)
-- Ne commitez jamais de numéro ou d’OTP ici.
--
--   update public.profiles
--   set role = 'admin'
--   where id = '<uuid-auth-du-compte>';
-- ---------------------------------------------------------------------------
