/**
 * simple concurrency runner for async tasks (array of functions returning promises)
 */
export async function runWithConcurrency(tasks, concurrency = 3) {
  const results = [];
  let i = 0;
  const workers = new Array(Math.min(concurrency, tasks.length)).fill(null).map(async () => {
    while (i < tasks.length) {
      const idx = i++;
      try {
        results[idx] = await tasks[idx]();
      } catch (err) {
        results[idx] = {error: err};
      }
    }
  });
  await Promise.all(workers);
  return results;
}
