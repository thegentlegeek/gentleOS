.pragma library

// Launcher search: case-insensitive matching that ranks a substring above a
// scattered subsequence, and prefers matches at the start of the text or of a
// word. match() returns { score, positions } (UTF-16 indexes into text, for
// highlighting) or null.

function isBoundary(text, i) {
    if (i === 0)
        return true;
    const prev = text[i - 1];
    const cur = text[i];
    return /[\s\-_./:()]/.test(prev) || (prev === prev.toLowerCase() && cur !== cur.toLowerCase());
}

function match(query, text) {
    if (!query)
        return { score: 0, positions: [] };
    if (!text)
        return null;
    const q = query.toLowerCase();
    const t = text.toLowerCase();

    const at = t.indexOf(q);
    if (at >= 0) {
        const positions = [];
        for (let i = 0; i < q.length; i++)
            positions.push(at + i);
        let score = 1000 - at - (t.length - q.length) * 0.1;
        if (at === 0)
            score += 300;
        else if (isBoundary(text, at))
            score += 150;
        return { score, positions };
    }

    // Subsequence: take each query character at the next contiguous position
    // or word start if there is one, else its next occurrence.
    const positions = [];
    let score = 0;
    let from = 0;
    let prev = -2;
    for (let qi = 0; qi < q.length; qi++) {
        let found = -1;
        for (let j = from; j < t.length; j++) {
            if (t[j] !== q[qi])
                continue;
            if (found < 0)
                found = j;
            if (j === prev + 1 || isBoundary(text, j)) {
                found = j;
                break;
            }
        }
        if (found < 0)
            return null;
        score += found === prev + 1 ? 40 : isBoundary(text, found) ? 30 : 5;
        score -= (found - from) * 0.5;
        positions.push(found);
        prev = found;
        from = found + 1;
    }
    return { score: score - t.length * 0.1, positions };
}

// Substring matches score from about 700; subsequences stay well below.
const substringScore = 500;

// Best match over several fields: [[text, weight, strict], ...]. A strict
// field (long descriptions, keywords) only counts substring matches: letters
// scattered across a sentence match nearly anything. Returns
// { score, field, positions } or null; field is the index of the winner.
function best(query, fields) {
    let result = null;
    for (let i = 0; i < fields.length; i++) {
        const m = match(query, fields[i][0]);
        if (!m || (fields[i][2] && m.score < substringScore))
            continue;
        const score = m.score * fields[i][1];
        if (!result || score > result.score)
            result = { score, field: i, positions: m.positions };
    }
    return result;
}

function escape(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// StyledText with the matched characters bold and in `color`.
function highlight(text, positions, color) {
    if (!text)
        return "";
    if (!positions || positions.length === 0)
        return escape(text);
    const hit = {};
    for (const p of positions)
        hit[p] = true;
    let out = "";
    let open = false;
    for (let i = 0; i < text.length; i++) {
        if (hit[i] && !open) {
            out += `<font color="${color}"><b>`;
            open = true;
        } else if (!hit[i] && open) {
            out += "</b></font>";
            open = false;
        }
        out += escape(text[i]);
    }
    return open ? out + "</b></font>" : out;
}
