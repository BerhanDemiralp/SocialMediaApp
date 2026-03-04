import 'dotenv/config';
import { Injectable } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService {
  client: SupabaseClient<any, any, any, any, any>;
  adminClient: SupabaseClient<any, any, any, any, any>;

  constructor() {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl || !supabaseAnonKey) {
      // eslint-disable-next-line no-console
      console.error('Supabase env missing', {
        hasUrl: !!supabaseUrl,
        hasAnonKey: !!supabaseAnonKey,
        hasServiceKey: !!supabaseServiceKey,
      });
      throw new Error(
        'Supabase URL or anon key is missing in environment variables',
      );
    }

    this.client = createClient(supabaseUrl, supabaseAnonKey);

    if (supabaseServiceKey) {
      this.adminClient = createClient(supabaseUrl, supabaseServiceKey);
    } else {
      // Fallback: use public client if service key is not configured
      // eslint-disable-next-line no-console
      console.warn(
        'SUPABASE_SERVICE_ROLE_KEY is not set; adminClient will use anon key (dev only).',
      );
      this.adminClient = this.client;
    }
  }
}
