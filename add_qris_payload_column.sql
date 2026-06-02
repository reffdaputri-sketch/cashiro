-- Execute this script in your Supabase SQL Editor to add the qris_payload column

ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS qris_payload TEXT;
