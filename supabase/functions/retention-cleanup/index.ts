// Edge Function: retention-cleanup
// Purpose: clean up orphaned photos in Storage/DB and enforce retention rules.
// Scheduled to run periodically via Supabase cron or external scheduler.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  // Initialize Supabase client with service role key for admin operations
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  
  if (!supabaseUrl || !supabaseServiceKey) {
    return json({ error: 'Missing environment variables' }, 500);
  }

  const supabase = createClient(supabaseUrl, supabaseServiceKey, {
    auth: { persistSession: false }
  });

  try {
    let totalCleaned = 0;
    const results = {
      orphanedFiles: 0,
      orphanedRows: 0,
      expiredPhotos: 0,
      errors: [] as string[]
    };

    // 1. Clean up orphaned storage files (files without DB records)
    try {
      const { data: storageFiles } = await supabase.storage
        .from('photos')
        .list('', { limit: 1000 });

      if (storageFiles) {
        for (const file of storageFiles) {
          // Check if file has corresponding DB record
          const { data: dbRecord } = await supabase
            .from('photos')
            .select('id')
            .eq('storage_path', file.name)
            .single();

          if (!dbRecord) {
            // Orphaned file - remove from storage
            const { error } = await supabase.storage
              .from('photos')
              .remove([file.name]);

            if (error) {
              results.errors.push(`Failed to delete orphaned file ${file.name}: ${error.message}`);
            } else {
              results.orphanedFiles++;
              totalCleaned++;
            }
          }
        }
      }
    } catch (e) {
      results.errors.push(`Storage cleanup error: ${String(e)}`);
    }

    // 2. Clean up orphaned DB records (records without storage files)
    try {
      const { data: dbRecords } = await supabase
        .from('photos')
        .select('id, storage_path')
        .limit(1000);

      if (dbRecords) {
        for (const record of dbRecords) {
          // Check if storage file exists
          const { data: storageFile } = await supabase.storage
            .from('photos')
            .download(record.storage_path);

          if (!storageFile) {
            // Orphaned DB record - remove from database
            const { error } = await supabase
              .from('photos')
              .delete()
              .eq('id', record.id);

            if (error) {
              results.errors.push(`Failed to delete orphaned record ${record.id}: ${error.message}`);
            } else {
              results.orphanedRows++;
              totalCleaned++;
            }
          }
        }
      }
    } catch (e) {
      results.errors.push(`Database cleanup error: ${String(e)}`);
    }

    // 3. Clean up expired photos (older than retention period - e.g., 2 years)
    try {
      const retentionDate = new Date();
      retentionDate.setFullYear(retentionDate.getFullYear() - 2); // 2 year retention

      const { data: expiredPhotos } = await supabase
        .from('photos')
        .select('id, storage_path')
        .lt('created_at', retentionDate.toISOString())
        .limit(100); // Process in batches

      if (expiredPhotos && expiredPhotos.length > 0) {
        const storagePaths = expiredPhotos.map(p => p.storage_path);
        const photoIds = expiredPhotos.map(p => p.id);

        // Delete from storage
        const { error: storageError } = await supabase.storage
          .from('photos')
          .remove(storagePaths);

        // Delete from database
        const { error: dbError } = await supabase
          .from('photos')
          .delete()
          .in('id', photoIds);

        if (storageError) {
          results.errors.push(`Failed to delete expired storage files: ${storageError.message}`);
        }
        if (dbError) {
          results.errors.push(`Failed to delete expired DB records: ${dbError.message}`);
        }
        if (!storageError && !dbError) {
          results.expiredPhotos = expiredPhotos.length;
          totalCleaned += expiredPhotos.length;
        }
      }
    } catch (e) {
      results.errors.push(`Retention cleanup error: ${String(e)}`);
    }

    // Log cleanup results for monitoring
    console.log('Retention cleanup completed:', {
      totalCleaned,
      ...results,
      timestamp: new Date().toISOString()
    });

    return json({
      status: 'completed',
      totalCleaned,
      details: results,
      timestamp: new Date().toISOString()
    });

  } catch (e) {
    console.error('Retention cleanup failed:', e);
    return json({ 
      error: 'cleanup_failed', 
      details: String(e),
      timestamp: new Date().toISOString()
    }, 500);
  }
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), { status, headers: jsonHeaders() });
}

function jsonHeaders(): HeadersInit {
  return {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
  };
}
