const std = @import("std");
const testing = std.testing;

const seperatorBonus = 5;
const adjacentCaseEqualBonus: i32 = 3;
const unmatchedLetterPenalty = -1;
const adjecencyBonus = 5;
const adjecencyIncrease = 1.2;
const caseEqualBonus: i32 = 7;
const firstLetterBonus = 12;
const leadingLetterPenalty = -3;
const maxLeadingLetterPolicy = -9;

pub fn match(pattern: []const u8, input: []const u8) bool {
    if (pattern.len > input.len) return false;
    var currentIndex: usize = 0;
    for (pattern) |each| {
        if (indexOf(input[currentIndex..], each)) |pIndex| {
            currentIndex = pIndex + 1;
        } else return false;
    }
    return true;
}

pub fn scoredMatch(pattern: []const u8, input: []const u8) ?i32 {
    if (pattern.len > input.len) return null;
    if (pattern.len == 0) return 0;
    var ramp: f32 = 1;
    var rampSum: f32 = 0.0;
    var score: i32 = 0;
    var inputIndex: usize = 0;
    for (pattern, 0..) |patternChar, patternIndex| {
        if (indexOf(input[inputIndex..], patternChar)) |position| {
            score += if (patternChar == input[position]) caseEqualBonus else 0;
            if (patternIndex == 0) {
                score += firstMatchScore(position);
            } else {
                var prev = input[position - 1];
                if (isSeparator(prev)) {
                    score += seperatorBonus;
                }
                if (inputIndex + 1 == position) {
                    ramp += (ramp * adjecencyIncrease);
                    rampSum += ramp - 1;
                    score += adjecencyBonus;
                    score += if (pattern[patternIndex - 1] == prev) adjacentCaseEqualBonus else 0;
                } else {
                    ramp = 1;
                }
            }
            inputIndex = position + 1;
        } else return null;
    }

    score += ((@intCast(i32, (input.len - pattern.len)) * unmatchedLetterPenalty));

    return score;
}

fn indexOf(haystack: []const u8, needle: u8) ?usize {
    const ascii = std.ascii;
    const lowercaseNeedle = ascii.toLower(needle);
    for (haystack, 0..) |item, index| {
        if (ascii.toLower(item) == lowercaseNeedle) return index;
    }
    return null;
}

fn firstMatchScore(position: usize) i32 {
    if (position == 0) return firstLetterBonus;
    return std.math.max(@intCast(i32, position) * leadingLetterPenalty, maxLeadingLetterPolicy);
}

inline fn isSeparator(char: u8) bool {
    return char == '_' or char == ':';
}

test "test fuzzy match" {
    try testing.expect(match("a", "bba"));
    try testing.expect(!match("a", "bb"));
    try testing.expect(!match("b", "aa"));
    try testing.expect(match("b", "aab"));
    try testing.expect(match("b", "aa:__x_b"));
    try testing.expect(match("b", "aa:__x_b"));
    try testing.expect(!match("aba", "aa:__x_b"));
    try testing.expect(match("aba", "aa:__x_ba"));
}

test "scoredMatch" {
    try testing.expectEqual(scoredMatch("a", "b"), null);
    try testing.expectEqual(scoredMatch("a", ""), null);
    try testing.expectEqual(scoredMatch("", "b"), 0);
    try testing.expectEqual(scoredMatch("a", "a").?, firstLetterBonus + caseEqualBonus);
    try testing.expectEqual(scoredMatch("a", "a").?, firstLetterBonus + caseEqualBonus);
    try testing.expectEqual(scoredMatch("a", "A").?, firstLetterBonus);
    try testing.expectEqual(scoredMatch("a", "ab").?, firstLetterBonus + caseEqualBonus + unmatchedLetterPenalty);
    try testing.expectEqual(scoredMatch("a", "1a").?, leadingLetterPenalty + unmatchedLetterPenalty + caseEqualBonus);
    try testing.expectEqual(scoredMatch("a", "12345a").?, maxLeadingLetterPolicy + (5 * unmatchedLetterPenalty) + caseEqualBonus);
}
