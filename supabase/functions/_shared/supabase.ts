import { createClient, SupabaseClient, User } from "jsr:@supabase/supabase-js@2";
import { jsonError } from "./http.ts";

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

/**
 * Validates the Authorization header and returns an authenticated `SupabaseClient` instance and the user.
 * Returns a Response object if validation fails, enabling direct early returns over throwing AppErrors.
 */
export const getAuthenticatedUserClient = async (
    req: Request
): Promise<{ userClient: SupabaseClient | null; user: User | null; errorResponse: Response | null }> => {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
        return {
            userClient: null,
            user: null,
            errorResponse: jsonError("Unauthorized", "UNAUTHORIZED", 401),
        };
    }

    const userClient = createClient(
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
 * Unauthenticated client, bound by whatever the `anon` role is granted.
 *
 * For endpoints that have no caller session and only read data anon may already
 * read (the public catalog). The service-role key buys nothing there and only
 * widens what a bug on that path can reach.
 */
export const getAnonClient = (): SupabaseClient => {
    return createClient(supabaseUrl(), supabaseAnonKey());
};

/**
 * Creates and returns an admin-level (Service Role) Supabaseclient.
 * Use with caution to bypass Row Level Security.
 */
export const getAdminClient = (): SupabaseClient => {
    return createClient(supabaseUrl(), supabaseServiceRoleKey());
};
