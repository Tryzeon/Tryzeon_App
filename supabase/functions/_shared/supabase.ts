import { createClient, SupabaseClient, User } from "jsr:@supabase/supabase-js@2";
import type { Database, Json } from "./database.types.ts";
import { jsonError } from "./http.ts";

export type DbClient = SupabaseClient<Database>;

/**
 * Narrows what a `jsonb`-returning RPC hands back. Those generate as `Json`:
 * the object is built by the SQL, so its shape is knowledge the schema cannot
 * hold and the caller has to supply. Written once here, behind a check that the
 * payload is an object at all.
 */
export const asJsonObject = <T>(value: Json | null | undefined): T | null =>
  typeof value === "object" && value !== null && !Array.isArray(value)
    ? value as T
    : null;

function requireEnv(name: string): string {
    const value = Deno.env.get(name);
    if (!value) {
        throw new Error(`Missing required environment variable: ${name}`);
    }
    return value;
}

/**
 * Readers rather than a constant object. This module is reachable from code
 * that never builds a client — `auth-session.ts` and its tests among them — and
 * validating at import made all three variables a condition of merely loading
 * the file, so a test with no environment failed before its first assertion.
 * Each caller now asks for the one variable it uses, when it uses it.
 */
export const supabaseUrl = (): string => requireEnv("SUPABASE_URL");
export const supabaseAnonKey = (): string => requireEnv("SUPABASE_ANON_KEY");

/** Service-role key. Unexported: `getAdminClient` is the only sanctioned reader. */
const supabaseServiceRoleKey = (): string => requireEnv("SUPABASE_SERVICE_ROLE_KEY");

export const getAuthenticatedUserClient = async (
    req: Request
): Promise<{ userClient: DbClient | null; user: User | null; errorResponse: Response | null }> => {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
        return {
            userClient: null,
            user: null,
            errorResponse: jsonError("Unauthorized", "UNAUTHORIZED", 401),
        };
    }

    const userClient = createClient<Database>(
        supabaseUrl(),
        supabaseAnonKey(),
        { global: { headers: { Authorization: authHeader } } }
    );

    const {
        data: { user },
        error: authError,
    } = await userClient.auth.getUser();

    if (authError || !user) {
        return {
            userClient: null,
            user: null,
            errorResponse: jsonError("Unauthorized", "UNAUTHORIZED", 401),
        };
    }

    return { userClient, user, errorResponse: null };
};

/**
 * For endpoints that have no caller session and only read data anon may already
 * read (the public catalog). The service-role key buys nothing there and only
 * widens what a bug on that path can reach.
 */
export const getAnonClient = (): DbClient => {
    return createClient<Database>(supabaseUrl(), supabaseAnonKey());
};

/** Service-role client. Bypasses Row Level Security — use with caution. */
export const getAdminClient = (): DbClient => {
    return createClient<Database>(supabaseUrl(), supabaseServiceRoleKey());
};
