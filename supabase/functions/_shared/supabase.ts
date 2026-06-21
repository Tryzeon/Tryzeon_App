import { createClient, SupabaseClient, User } from "jsr:@supabase/supabase-js@2";
import { jsonError } from "./http.ts";

export const CONFIG = {
    SUPABASE_URL: Deno.env.get("SUPABASE_URL")!,
    SUPABASE_SERVICE_ROLE_KEY: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
}

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
        CONFIG.SUPABASE_URL,
        CONFIG.SUPABASE_SERVICE_ROLE_KEY,
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
 * Creates and returns an admin-level (Service Role) Supabaseclient. 
 * Use with caution to bypass Row Level Security.
 */
export const getAdminClient = (): SupabaseClient => {
    return createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_SERVICE_ROLE_KEY);
};
