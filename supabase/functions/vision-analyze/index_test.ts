// @ts-nocheck
// Basic Deno test for the vision-analyze handler. Verifies fallback behavior w/o provider keys.
import { handleRequest } from './index.ts';

Deno.test('vision-analyze returns analyses with placeholder when no provider configured', async () => {
  const req = new Request('http://localhost', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ paths: ['user123/2025/08/10/photo.jpg'] }),
  });
  const res = await handleRequest(req);
  if (res.status !== 200) {
    throw new Error(`unexpected status ${res.status}`);
  }
  const json = await res.json();
  if (!json || !Array.isArray(json.analyses) || json.analyses.length !== 1) {
    throw new Error('invalid analyses shape');
  }
  const first = json.analyses[0];
  if (!first.path || !Array.isArray(first.observations)) {
    throw new Error('missing fields');
  }
});
