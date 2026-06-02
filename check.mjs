import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gxahwrxfdotunixlckwx.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd4YWh3cnhmZG90dW5peGxja3d4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTk2NDgxNiwiZXhwIjoyMDk1NTQwODE2fQ.8TwKVJ0wl7yTN2RfbneXHkR4xxmkmtAp0OFqU8RcQqk';
const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
  const { data, error } = await supabase.from('stores').select('id, store_name, qris_payload').limit(5);
  console.log('Error:', error);
  console.log('Data:', data);
}

check();
