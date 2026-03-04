import 'dotenv/config';
import { SupabaseClient } from '@supabase/supabase-js';
export declare class SupabaseService {
    client: SupabaseClient<any, any, any, any, any>;
    adminClient: SupabaseClient<any, any, any, any, any>;
    constructor();
}
