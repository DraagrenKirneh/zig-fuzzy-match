pub const Matcher = struct {
    allocator: std.mem.Allocator,
    pattern: []const u8,
    indexes: []usize,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, pattern: []const u8) !Self {
        var indexes = try allocator.alloc(usize, std.math.max(pattern.len, 64));
        return Self{ .allocator = allocator, .pattern = pattern, .indexes = indexes };
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.indexes);
    }

    fn matches(self: *Self, str: []const u8) bool {
        if (self.pattern.len > str.len) return false;
        var currentIndex: usize = 0;
        for (self.pattern) |each, i| {
            var result = indexOf(str, currentIndex, each);
            if (result) |pIndex| {
                self.indexes[i] = pIndex;
                currentIndex = pIndex + 1;
            } else return false;
        }
        return true;
    }

    fn indexScore(self: Self) i32 {
        var ramp: f32 = 1;
        var sum: f32 = 0.0;
        var prev = self.indexes[0];
        for (self.indexes[1..self.pattern.len]) |each| {
            ramp = if (prev + 1 == each) ramp + (ramp * adjecencyIncrease) else 1;
            sum += ramp - 1;
            prev = each;
        }
        return @floatToInt(i32, std.math.round(sum));
    }

    pub fn scoreString(self: *Self, str: []const u8) ?i32 {
        if (self.pattern.len > str.len) return null;
        if (self.pattern.len == 0) return 0;
        if (!self.matches(str)) return null;
        const firstIndex = self.indexes[0];
        var score: i32 = if (self.pattern[0] == str[firstIndex]) caseEqualBonus else 0;
        score += if (firstIndex == 0) firstLetterBonus else std.math.max(@intCast(i32, firstIndex) * leadingLetterPenalty, maxLeadingLetterPolicy);

        var i: usize = 1;
        const end: usize = self.pattern.len - 1;
        while (i <= end) : (i += 1) {
            const ix = self.indexes[i];
            const prev = str[ix - 1];
            if (isSeparator(prev)) {
                score += seperatorBonus;
            } else if (self.indexes[i - 1] + 1 == ix) {
                score += adjecencyBonus;
                score += if (prev == self.pattern[i - 1]) adjacentCaseEqualBonus else 0;
            }
            if (str[ix] == self.pattern[i]) {
                score += caseEqualBonus;
            }
        }

        score += self.indexScore() + ((@intCast(i32, (str.len - self.pattern.len)) * unmatchedLetterPenalty));

        return score;
    }
};
