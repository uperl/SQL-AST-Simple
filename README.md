# SQL::AST::Simple ![static](https://github.com/uperl/SQL-AST-Simple/workflows/static/badge.svg) ![linux](https://github.com/uperl/SQL-AST-Simple/workflows/linux/badge.svg)

Parse SQL into a plain Perl data structure and back again

# SYNOPSIS

```perl
use SQL::AST::Simple qw( parse unparse );

my $ast = parse('SELECT a, b FROM t WHERE a > 1', dialect => 'postgresql');

# $ast is an array reference of statements, each a tree of plain
# hashes, arrays and scalars.  Poke at it however you like:
$ast->[0]{Query}{body}{Select}{from}[0]{relation}{Table}{name}[0]{Identifier}{value} = 'u';

say unparse($ast);   # SELECT a, b FROM u WHERE a > 1
```

# DESCRIPTION

This module bundles the Rust
[sqlparser](https://github.com/apache/datafusion-sqlparser-rs) crate and
exposes exactly two operations: turning SQL text into the parser's abstract
syntax tree as an ordinary Perl data structure, and turning such a data
structure back into SQL text.  There is no object layer; the tree is what
the crate's serde serialization produces, decoded from JSON.  That keeps
the module small and makes every node the crate knows about available
without any wrapping, at the cost of a somewhat verbose structure.

Nothing is exported by default.

# FUNCTIONS

## parse

```perl
my $ast = parse($sql);
my $ast = parse($sql, dialect => $name);
```

Parses `$sql`, which may contain several semicolon separated statements,
and returns an array reference with one element per statement.  Throws an
exception with the parser's message, including line and column, if the
text cannot be parsed.

Options:

- dialect

    Which SQL dialect to parse with.  Defaults to `generic`, which is the
    most permissive.  Recognized names (case insensitive) are `generic`,
    `ansi`, `postgresql` (or `postgres`), `mysql`, `sqlite`, `mssql`,
    `oracle`, `snowflake`, `bigquery`, `redshift`, `clickhouse`,
    `duckdb`, `databricks`, `hive`, `spark` (or `sparksql`) and
    `teradata`.

## unparse

```perl
my $sql = unparse($ast);
my $sql = unparse($ast, pretty => 1);
```

Takes an array reference of statements as returned by ["parse"](#parse), or a
single statement hash reference, and returns the SQL text.  Multiple
statements are joined with `"; "`.  Throws an exception if the structure
does not deserialize into a valid AST.

Options:

- pretty

    If true, statements are formatted with indentation and newlines rather
    than on a single line, and are joined with `";\n"`.

# THE DATA STRUCTURE

The tree mirrors the Rust types of the `sqlparser` crate one to one, as
serialized by serde.  A few rules of thumb cover most of it:

- Rust enums are "externally tagged": a hash with a single key naming the
variant, whose value is the payload.  A `SELECT` statement is
`{ Query => {...} }`, a column reference in an expression is
`{ Identifier => {...} }`, a literal is `{ Value => {...} }`.
Variants without payload are plain strings.
- Rust structs are hashes keyed by field name; `Option` fields that are
absent are `undef`; `Vec` fields are array references.
- Booleans come back as JSON boolean objects.  When you set a boolean field
yourself use `\1` or `\0` (or the `true`/`false` constants from your
JSON module).  A plain Perl `1` would be encoded as a number and rejected
by ["unparse"](#unparse).
- Numeric literals are kept as strings, exactly as they appeared in the
source, so that precision is never lost.  Any field that holds a string
must be given a Perl string; if you have computed a number, stringify it
first.
- Most nodes carry a `span` hash recording where they appeared in the
source.  ["unparse"](#unparse) ignores the contents but requires the field to be
present, so the easiest way to build a new node is to parse a small
snippet and lift the piece you need out of the result, rather than
constructing hashes by hand.

The easiest way to learn the shape for a given construct is to parse an
example and dump it.  The exact shape depends on the bundled crate
version, which is pinned in the distribution's `ffi/Cargo.toml`; a
release that bumps it may change the structure and will say so in the
change log.

# CAVEATS

The parser is syntactic only and deliberately permissive.  It will accept
some SQL that a given database would reject, and occasionally reject
vendor syntax it does not yet know.  Round tripping is not byte for byte:
comments are dropped, keywords are upper cased, and whitespace is
normalized.

Building this distribution requires a Rust toolchain (`cargo`) at
install time.

# SEE ALSO

- [https://github.com/apache/datafusion-sqlparser-rs](https://github.com/apache/datafusion-sqlparser-rs)

    The parser this module wraps.

- [FFI::Platypus::Lang::Rust](https://metacpan.org/pod/FFI::Platypus::Lang::Rust)

    How the Rust code is bundled and called.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
