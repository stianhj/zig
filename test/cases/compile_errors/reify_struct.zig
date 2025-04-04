comptime {
    @Type(.{ .@"struct" = .{
        .layout = .auto,
        .fields = &.{.{
            .name = "foo",
            .type = u32,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = 4,
        }},
        .decls = &.{},
        .is_tuple = true,
    } });
}
comptime {
    @Type(.{ .@"struct" = .{
        .layout = .auto,
        .fields = &.{.{
            .name = "3",
            .type = u32,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = 4,
        }},
        .decls = &.{},
        .is_tuple = true,
    } });
}
comptime {
    @Type(.{ .@"struct" = .{
        .layout = .auto,
        .fields = &.{.{
            .name = "0",
            .type = u32,
            .default_value_ptr = null,
            .is_comptime = true,
            .alignment = 4,
        }},
        .decls = &.{},
        .is_tuple = true,
    } });
}
comptime {
    @Type(.{ .@"struct" = .{
        .layout = .@"extern",
        .fields = &.{.{
            .name = "0",
            .type = u32,
            .default_value_ptr = null,
            .is_comptime = true,
            .alignment = 4,
        }},
        .decls = &.{},
        .is_tuple = false,
    } });
}
comptime {
    @Type(.{ .@"struct" = .{
        .layout = .@"packed",
        .fields = &.{.{
            .name = "0",
            .type = u32,
            .default_value_ptr = null,
            .is_comptime = true,
            .alignment = 4,
        }},
        .decls = &.{},
        .is_tuple = false,
    } });
}

// error
//
// :2:5: error: tuple cannot have non-numeric field 'foo'
// :16:5: error: tuple field name '3' does not match field index 0
// :30:5: error: comptime field without default initialization value
// :44:5: error: extern struct fields cannot be marked comptime
// :58:5: error: alignment in a packed struct field must be set to 0
