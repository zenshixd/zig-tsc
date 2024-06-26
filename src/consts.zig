const std = @import("std");

pub const PUNCTUATION_CHARS = ".,:;()[]'\"{}";
pub const OPERATOR_CHARS = "<>?+-=*|&!%/\\";
pub const WHITESPACE = " \t\r\n";

pub const keywords_map = std.StaticStringMap(TokenType).initComptime(.{
    .{ "var", TokenType.Var },
    .{ "let", TokenType.Let },
    .{ "const", TokenType.Const },
    .{ "async", TokenType.Async },
    .{ "await", TokenType.Await },
    .{ "function", TokenType.Function },
    .{ "return", TokenType.Return },
    .{ "for", TokenType.For },
    .{ "while", TokenType.While },
    .{ "break", TokenType.Break },
    .{ "continue", TokenType.Continue },
    .{ "do", TokenType.Do },
    .{ "if", TokenType.If },
    .{ "else", TokenType.Else },
    .{ "get", TokenType.Get },
    .{ "set", TokenType.Set },
    .{ "class", TokenType.Class },
    .{ "abstract", TokenType.Abstract },
    .{ "extends", TokenType.Extends },
    .{ "interface", TokenType.Interface },
    .{ "type", TokenType.Type },
    .{ "case", TokenType.Case },
    .{ "debugger", TokenType.Debugger },
    .{ "default", TokenType.Default },
    .{ "delete", TokenType.Delete },
    .{ "enum", TokenType.Enum },
    .{ "import", TokenType.Import },
    .{ "export", TokenType.Export },
    .{ "false", TokenType.False },
    .{ "true", TokenType.True },
    .{ "finally", TokenType.Finally },
    .{ "try", TokenType.Try },
    .{ "catch", TokenType.Catch },
    .{ "in", TokenType.In },
    .{ "of", TokenType.Of },
    .{ "instanceof", TokenType.Instanceof },
    .{ "typeof", TokenType.Typeof },
    .{ "new", TokenType.New },
    .{ "null", TokenType.Null },
    .{ "undefined", TokenType.Undefined },
    .{ "super", TokenType.Super },
    .{ "switch", TokenType.Switch },
    .{ "this", TokenType.This },
    .{ "throw", TokenType.Throw },
    .{ "void", TokenType.Void },
    .{ "with", TokenType.With },
    .{ "as", TokenType.As },
    .{ "implements", TokenType.Implements },
    .{ "package", TokenType.Package },
    .{ "private", TokenType.Private },
    .{ "protected", TokenType.Protected },
    .{ "public", TokenType.Public },
    .{ "static", TokenType.Static },
    .{ "yield", TokenType.Yield },
    .{ "from", TokenType.From },
    .{ "any", TokenType.Any },
    .{ "unknown", TokenType.Unknown },
});

pub const TokenType = enum(u8) {
    Eof,
    NewLine,
    Whitespace,
    LineComment,
    MultilineComment,
    Identifier,
    Keyword,
    StringConstant,
    NumberConstant,
    BigIntConstant,
    Ampersand,
    AmpersandAmpersand,
    Caret,
    Bar,
    BarBar,
    Plus,
    PlusPlus,
    Minus,
    MinusMinus,
    Star,
    StarStar,
    Slash,
    Percent,
    ExclamationMark,
    ExclamationMarkEqual,
    ExclamationMarkEqualEqual,
    Equal,
    EqualEqual,
    EqualEqualEqual,
    GreaterThan,
    GreaterThanEqual,
    GreaterThanGreaterThan,
    GreaterThanGreaterThanEqual,
    GreaterThanGreaterThanGreaterThan,
    GreaterThanGreaterThanGreaterThanEqual,
    LessThan,
    LessThanEqual,
    LessThanLessThan,
    LessThanLessThanEqual,
    AmpersandEqual,
    AmpersandAmpersandEqual,
    BarEqual,
    BarBarEqual,
    CaretEqual,
    PlusEqual,
    MinusEqual,
    StarEqual,
    StarStarEqual,
    SlashEqual,
    PercentEqual,
    OpenCurlyBrace,
    CloseCurlyBrace,
    OpenSquareBracket,
    CloseSquareBracket,
    OpenParen,
    CloseParen,
    Dot,
    DotDotDot,
    Comma,
    Semicolon,
    Colon,
    QuestionMark,
    QuestionMarkDot,
    QuestionMarkQuestionMark,
    QuestionMarkQuestionMarkEqual,
    Tilde,
    Hash,

    // Keywords
    Var,
    Let,
    Const,
    Async,
    Await,
    Function,
    Return,
    For,
    While,
    Break,
    Continue,
    Do,
    If,
    Else,
    Get,
    Set,
    Abstract,
    Class,
    Extends,
    Interface,
    Type,
    Case,
    Debugger,
    Default,
    Delete,
    Enum,
    Import,
    Export,
    False,
    True,
    Finally,
    Try,
    Catch,
    In,
    Of,
    Instanceof,
    Typeof,
    New,
    Null,
    Undefined,
    Super,
    Switch,
    This,
    Throw,
    Void,
    With,
    As,
    Implements,
    Package,
    Private,
    Protected,
    Public,
    Static,
    Yield,
    From,
    Any,
    Unknown,
};

pub const Token = struct {
    type: TokenType,
    pos: usize,
    end: usize,
    line: usize,
    value: ?[]const u8,

    pub fn format(self: Token, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.writeAll("Token(.type = ");
        try writer.writeAll(@tagName(self.type));
        try writer.writeAll(", .pos = ");
        try writer.print("{}", .{self.pos});
        try writer.writeAll(", .end = ");
        try writer.print("{}", .{self.end});
        try writer.writeAll(", .line = ");
        try writer.print("{}", .{self.line});
        if (self.value) |value| {
            try writer.writeAll(", .value = ");
            try writer.writeAll(value);
        }
        try writer.writeAll(")");
    }
};

pub const RESERVED_WORDS = [_][]const u8{
    "await",
    "break",
    "case",
    "catch",
    "class",
    "const",
    "continue",
    "debugger",
    "default",
    "delete",
    "do",
    "else",
    "enum",
    "export",
    "extends",
    "false",
    "finally",
    "for",
    "function",
    "if",
    "import",
    "in",
    "instanceof",
    "new",
    "null",
    "return",
    "super",
    "switch",
    "this",
    "throw",
    "true",
    "try",
    "typeof",
    "var",
    "void",
    "while",
    "with",
    "yield",
};

pub fn isReservedWord(word: []const u8) bool {
    for (RESERVED_WORDS) |reserved_word| {
        if (std.mem.eql(u8, reserved_word, word)) {
            return true;
        }
    }
    return false;
}
