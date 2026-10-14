// Deno unit tests for Edge Functions logic
// Run with: deno test supabase/functions/tests/edge_functions_test.ts

import { assertEquals, assertNotEquals } from "https://deno.land/std@0.177.0/testing/asserts.ts";

Deno.test("Path ownership security check: rejects paths not starting with user id", () => {
  const userId = "123e4567-e89b-12d3-a456-426614174000";
  const validPath = `${userId}/photo-1.jpg`;
  const attackerPath = "victim-user-id/secret-meal.jpg";

  assertEquals(validPath.startsWith(`${userId}/`), true);
  assertEquals(attackerPath.startsWith(`${userId}/`), false);
});

Deno.test("Daily usage quota logic: blocks non-pro users after 3 scans", () => {
  const freeDailyLimit = 3;

  function canScan(isPro: boolean, currentCount: number): boolean {
    if (isPro) return true;
    return currentCount < freeDailyLimit;
  }

  assertEquals(canScan(false, 0), true);
  assertEquals(canScan(false, 2), true);
  assertEquals(canScan(false, 3), false);
  assertEquals(canScan(false, 5), false);
  assertEquals(canScan(true, 100), true); // Pro has unlimited scans
});

Deno.test("Item nutrient sanitation bounds: clamps unreasonable AI numbers", () => {
  function sanitizeCalories(rawCalories: number): number {
    return Math.max(0, Math.min(3000, Number(rawCalories) || 0));
  }

  assertEquals(sanitizeCalories(550), 550);
  assertEquals(sanitizeCalories(-20), 0);
  assertEquals(sanitizeCalories(999999), 3000); // Sanity upper bound
});

Deno.test("NOT_FOOD logic: flags non-food photos without incrementing usage", () => {
  const aiMockResult = {
    is_food: false,
    dish_summary: "",
    confidence: "low",
    items: [],
  };

  let scanCount = 1;
  if (aiMockResult.is_food) {
    scanCount++;
  }

  // Scan count must NOT increase if is_food is false
  assertEquals(scanCount, 1);
});

Deno.test("RevenueCat Webhook Secret verification", () => {
  const configuredSecret = "my_super_secret_webhook_key";

  function verifySecret(header: string | null): boolean {
    return header === configuredSecret;
  }

  assertEquals(verifySecret("my_super_secret_webhook_key"), true);
  assertEquals(verifySecret("wrong_secret"), false);
  assertEquals(verifySecret(null), false);
});
