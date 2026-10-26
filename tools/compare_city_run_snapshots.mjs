export function compareRecords(before, after, options = {}) {
  const geometryTolerance = options.geometryTolerance ?? 0.002;
  const colorTolerance = options.colorTolerance ?? (1 / 255 + 0.00001);
  const equivalent = (a, b, field) => {
    if (a === b) return true;
    if (typeof a === 'number' && typeof b === 'number') {
      const tolerance = ['cf', 'size', 'pivot'].includes(field) ? geometryTolerance : /color/i.test(field) ? colorTolerance : 0.00001;
      return Math.abs(a - b) <= tolerance;
    }
    if (a && b && typeof a === 'object' && typeof b === 'object') {
      const keys = [...new Set([...Object.keys(a), ...Object.keys(b)])];
      return keys.every(key => equivalent(a[key], b[key], field));
    }
    return false;
  };
  const fields = (a, b) => [...new Set([...Object.keys(a), ...Object.keys(b)])]
    .filter(key => key !== 'pivot' && !equivalent(a[key], b[key], key));
  const group = records => {
    const groups = new Map();
    for (const record of records) {
      const key = record.path + '|' + record.class;
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key).push(record);
    }
    return groups;
  };
  const left = group(before), right = group(after);
  const result = { added: [], removed: [], changed: [] };
  for (const key of new Set([...left.keys(), ...right.keys()])) {
    const a = [...(left.get(key) ?? [])], b = [...(right.get(key) ?? [])];
    for (let i = a.length - 1; i >= 0; i--) {
      const match = b.findIndex(record => fields(a[i], record).length === 0);
      if (match >= 0) { a.splice(i, 1); b.splice(match, 1); }
    }
    while (a.length && b.length) {
      const original = a.shift();
      let chosen = 0, distance = Infinity;
      b.forEach((record, index) => {
        const d = original.cf && record.cf ? original.cf.slice(0, 3).reduce((sum, v, axis) => sum + (v - record.cf[axis]) ** 2, 0) : fields(original, record).length;
        if (d < distance) { distance = d; chosen = index; }
      });
      const replacement = b.splice(chosen, 1)[0];
      result.changed.push({ before: original, after: replacement, fields: fields(original, replacement) });
    }
    result.removed.push(...a); result.added.push(...b);
  }
  return result;
}
