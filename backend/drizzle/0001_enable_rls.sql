-- Techy Trashker: deny direct client access to domain tables.
--
-- Semua akses data lewat backend Fastify (Postgres connection sebagai role
-- `postgres` yang bypass RLS). Supabase PostgREST tetap terekspos dengan anon
-- key, jadi RLS tanpa policy memastikan tabel tidak bisa dibaca/ditulis
-- langsung dari client meskipun anon key bocor.
--
-- Kalau nanti ingin akses langsung dari Supabase client, tambahkan policy
-- eksplisit di migration baru.

ALTER TABLE "profiles" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "news" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "waste_banks" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "deposits" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "deposit_items" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "rewards" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "redemptions" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "point_transactions" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "qr_sessions" ENABLE ROW LEVEL SECURITY;
