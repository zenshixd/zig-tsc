const std = @import("std");
const String = @import("string.zig").String;
const Symbol = @import("symbol_table.zig").Symbol;

pub const PUNCTUATION_CHARS = ".,:;()[]'\"{}";
pub const OPERATOR_CHARS = "<>?+-=*|&!%/\\";
pub const WHITESPACE = " \t\r\n";
// zig fmt: off
pub const keywords_map = std.ComptimeStringMap(TokenType, .{
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
    .{ "class", TokenType.Class },
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
    .{ "instanceof", TokenType.Instanceof },
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
    Instanceof,
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
    From
};
// zig fmt: on

pub const Token = struct {
    type: TokenType,
    value: ?[]const u8,
};
