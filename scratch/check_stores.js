const fs = require('fs');
const path = require('path');
const https = require('https');

// Parse .env.local manually
const envPath = path.resolve(__dirname, '../.env.local');
const envContent = fs.readFileSync(envPath, 'utf8');
const env = {};
envContent.split('\n').forEach(line => {
  const match = line.match(/^\s*([\w.-]+)\s*=\s*(.*)?\s*$/);
  if (match) {
    const key = match[1];
    let value = match[2] || '';
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    }
    env[key] = value.trim();
  }
});

const supabaseUrl = env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error("Missing environment variables!");
  process.exit(1);
}

function get(urlPath) {
  return new Promise((resolve, reject) => {
    const url = `${supabaseUrl}/rest/v1/${urlPath}`;
    const options = {
      headers: {
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`
      }
    };
    https.get(url, options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', reject);
  });
}

async function run() {
  try {
    const stores = await get('stores?select=id,store_name,owner_name,address,city_id');
    console.log("Registered Stores:");
    console.log(JSON.stringify(stores, null, 2));

    const sellers = await get('sellers?select=id,slug,store_id');
    console.log("Registered Sellers:");
    console.log(JSON.stringify(sellers, null, 2));
  } catch (err) {
    console.error(err);
  }
}

run();
