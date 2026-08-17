import Toybox.Lang;

function isValidTargetRange(lower, upper) as Boolean {
    return lower instanceof Number && upper instanceof Number
        && lower > 0 && upper > lower;
}

function acceptsTargetBound(value, companion, editingLower) as Boolean {
    if (!(value instanceof Number) || value <= 0) { return false; }
    if (!(companion instanceof Number) || companion <= 0) { return true; }
    return editingLower ? value < companion : value > companion;
}
