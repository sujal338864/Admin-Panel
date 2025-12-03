
const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://zyryndjeojrzvoubsqsg.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp5cnluZGplb2pyenZvdWJzcXNnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzczMTI5NiwiZXhwIjoyMDczMzA3Mjk2fQ.UC3Dop1OxnHvPEnuN4zstB0emdbvISNQWw8jVXhbtCY";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

module.exports = supabase;


// // models/supabaseClient.js
// const { createClient } = require("@supabase/supabase-js");

// const SUPABASE_URL = "https://zyryndjeojrzvoubsqsg.supabase.co"; // your project URL
// const SUPABASE_KEY = "YOUR_SERVICE_ROLE_KEY"; // ⚠️ from Supabase → Project → Settings → API

// const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// module.exports = supabase;
