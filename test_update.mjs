import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function test() {
  const storeId = 'eb0c09d6-9cd7-405f-bfa6-902c10c79086'; // From check.mjs output
  const { data, error } = await supabase
    .from('stores')
    .update({ banners: ['https://res.cloudinary.com/demo/image/upload/v1312461204/sample.jpg'] })
    .eq('id', storeId)
    .select();
  
  console.log('Error:', error);
  console.log('Data:', data);
}
test();
