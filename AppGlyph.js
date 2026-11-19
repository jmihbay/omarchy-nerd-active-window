function parseRules(text, filename) {
  try {
    var rules = JSON.parse(text.replace(/^[ \t]*\/\/.*$/gm, ""));
    if (Array.isArray(rules)) return rules;
  } catch (error) {
    if (text) console.warn("Nerd Active Window: invalid " + filename + ": " + error.message);
  }
  return [];
}

function matches(rule, value) {
  return Array.isArray(rule.match) && rule.match.some(function (name) {
    return typeof name === "string" && name.length > 0 && value.includes(name.toLowerCase());
  });
}

function vectorFor(appClass, rules) {
  var value = String(appClass || "").toLowerCase();
  for (var rule of rules) {
    if (rule && Number.isFinite(rule.width) && rule.width > 0
        && Number.isFinite(rule.height) && rule.height > 0
        && typeof rule.path === "string" && rule.path.trim()
        && matches(rule, value)) return rule;
  }
  return null;
}

function glyphFor(appClass, initialClass, rules) {
  var value = (String(appClass || "") + " " + String(initialClass || "")).toLowerCase();
  for (var rule of rules) {
    if (!rule || typeof rule.codepoint !== "string"
        || !/^[0-9a-f]{1,6}$/i.test(rule.codepoint)) continue;

    var codepoint = parseInt(rule.codepoint, 16);
    if (codepoint > 0x10ffff || (codepoint >= 0xd800 && codepoint <= 0xdfff)) continue;

    if (matches(rule, value)) return String.fromCodePoint(codepoint);
  }
  return null;
}

function selectIcon(appClass, initialClass, userGlyphs, userVectors, defaultGlyphs, defaultVectors) {
  var vector = vectorFor(appClass, userVectors);
  if (vector) return { vector: vector, glyph: "" };

  var glyph = glyphFor(appClass, initialClass, userGlyphs);
  if (glyph) return { vector: null, glyph: glyph };

  vector = vectorFor(appClass, defaultVectors);
  if (vector) return { vector: vector, glyph: "" };

  return { vector: null, glyph: glyphFor(appClass, initialClass, defaultGlyphs) ?? "\uf2d0" };
}

// Omarchy's tooltip accepts rich text; escape all application-owned strings.
function tooltipText(title, appClass) {
  return (String(title || "") + (appClass ? "\n" + String(appClass) : ""))
    .slice(0, 1024)
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;").replace(/'/g, "&#39;");
}

function onCurrentWorkspace(activated, windowWorkspace, currentWorkspace, pinned) {
  return Boolean(activated) && (Boolean(pinned) || (currentWorkspace > 0 && windowWorkspace === currentWorkspace) || (currentWorkspace < 0 && windowWorkspace === currentWorkspace));
}
