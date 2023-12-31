//! Toy chess engine

const std = @import("std");
const ascii = std.ascii;

const move_depth = 1;
const board_dim = 2;

const Bitboard = std.meta.Int(.unsigned, board_dim * board_dim);

const PieceType = enum(u8) {
    pawn,
    night,
    bishop,
    rook,
    queen,
    king,
};

const PieceColor = enum(u8) {
    white = 0,
    black = 1,
};

const Piece = struct {
    type: PieceType,
    color: PieceColor,
};

// GEN PAWN ATTACK MAP

// 8x8 masks
// const not_a_file = 0xfefefefefefefefe;
// const not_h_file = 0x7f7f7f7f7f7f7f7f;

// 2x2
const not_a_file = 0x05;
const not_b_file = 0x0a;

fn northWestOne(bb: Bitboard) Bitboard {
    return (bb & not_a_file) << board_dim + 1;
}

fn southWestOne(bb: Bitboard) Bitboard {
    return (bb & not_a_file) >> board_dim - 1;
}

fn southEastOne(bb: Bitboard) Bitboard {
    return (bb & not_b_file) >> board_dim + 1;
}

fn northEastOne(bb: Bitboard) Bitboard {
    return (bb & not_b_file) << board_dim - 1;
}

fn eastPawnAttacks(c: PieceColor, bb: Bitboard) Bitboard {
    switch (c) {
        .white => return northEastOne(bb),
        .black => return southEastOne(bb),
    }
}

fn westPawnAttacks(c: PieceColor, bb: Bitboard) Bitboard {
    switch (c) {
        .white => return northWestOne(bb),
        .black => return southWestOne(bb),
    }
}

fn pawnAnyAttacks(c: PieceColor, bb: Bitboard) Bitboard {
    return westPawnAttacks(c, bb) | eastPawnAttacks(c, bb);
}

fn eastCapturablePawns(c: PieceColor, bb: Bitboard) Bitboard {
    return bb & westPawnAttacks(@enumFromInt((@intFromEnum(c) + 1) % 2), bb);
}

fn westCapturablePawns(c: PieceColor, bb: Bitboard) Bitboard {
    return bb & eastPawnAttacks(@enumFromInt((@intFromEnum(c) + 1) % 2), bb);
}

fn memToBoardCoords(row_index: u8, col_index: u8) @Vector(2, u8) {
    if (col_index > board_dim or row_index > board_dim) {
        std.debug.print("Bad pos ({d},{d})\n", .{ row_index, col_index });
        unreachable;
    }
    return @Vector(2, u8){ 'a' + col_index, board_dim - row_index };
}

fn boardToMemCoords(col_chr: u8, row: u8) @Vector(2, u8) {
    const col_index: i8 = @intCast(ascii.toLower(col_chr) - 'a');
    if (col_index < 0 or col_index > board_dim - 1 or row < 1 or row > board_dim) {
        std.debug.print("Bad pos ({c},{d})\n", .{ col_chr, row });
        unreachable;
    }
    return @Vector(2, u8){ board_dim - row, @intCast(col_index) };
}

// fn initPieceSets(piece_sets: []PieceSet) !void {
//     for (0..8) |col_index|
//         piece_sets[@intFromEnum(PieceColor.white)].pieces[col_index] =
//             Piece{ .type = .pawn, .pos = boardToMemCoords(@intCast('a' + col_index), 2) };
//     piece_sets[@intFromEnum(PieceColor.white)].pieces[8] = Piece{ .type = .rook, .pos = boardToMemCoords('a', 1) };
//     piece_sets[@intFromEnum(PieceColor.white)].pieces[9] = Piece{ .type = .night, .pos = boardToMemCoords('b', 1) };
//     piece_sets[@intFromEnum(PieceColor.white)].pieces[10] = Piece{ .type = .bishop, .pos = boardToMemCoords('c', 1) };
//     piece_sets[@intFromEnum(PieceColor.white)].pieces[11] = Piece{ .type = .queen, .pos = boardToMemCoords('d', 1) };
//     piece_sets[@intFromEnum(PieceColor.white)].pieces[12] = Piece{ .type = .king, .pos = boardToMemCoords('e', 1) };
//     piece_sets[@intFromEnum(PieceColor.white)].pieces[13] = Piece{ .type = .bishop, .pos = boardToMemCoords('f', 1) };
//     piece_sets[@intFromEnum(PieceColor.white)].pieces[14] = Piece{ .type = .night, .pos = boardToMemCoords('g', 1) };
//     piece_sets[@intFromEnum(PieceColor.white)].pieces[15] = Piece{ .type = .rook, .pos = boardToMemCoords('h', 1) };

//     for (0..8) |col_index|
//         piece_sets[@intFromEnum(PieceColor.black)].pieces[col_index] =
//             Piece{ .type = .pawn, .pos = boardToMemCoords(@intCast('a' + col_index), 7) };
//     piece_sets[@intFromEnum(PieceColor.black)].pieces[8] = Piece{ .type = .rook, .pos = boardToMemCoords('a', 8) };
//     piece_sets[@intFromEnum(PieceColor.black)].pieces[9] = Piece{ .type = .night, .pos = boardToMemCoords('b', 8) };
//     piece_sets[@intFromEnum(PieceColor.black)].pieces[10] = Piece{ .type = .bishop, .pos = boardToMemCoords('c', 8) };
//     piece_sets[@intFromEnum(PieceColor.black)].pieces[12] = Piece{ .type = .king, .pos = boardToMemCoords('d', 8) };
//     piece_sets[@intFromEnum(PieceColor.black)].pieces[11] = Piece{ .type = .queen, .pos = boardToMemCoords('e', 8) };
//     piece_sets[@intFromEnum(PieceColor.black)].pieces[13] = Piece{ .type = .bishop, .pos = boardToMemCoords('f', 8) };
//     piece_sets[@intFromEnum(PieceColor.black)].pieces[14] = Piece{ .type = .night, .pos = boardToMemCoords('g', 8) };
//     piece_sets[@intFromEnum(PieceColor.black)].pieces[15] = Piece{ .type = .rook, .pos = boardToMemCoords('h', 8) };
// }

/// Setup piece sets for 2x2 board
// fn initPieceSetsSmol(piece_sets: []PieceSet) !void {
//     piece_sets[@intFromEnum(PieceColor.white)].pieces[0] =
//         Piece{ .type = .pawn, .pos = boardToMemCoords('a', 1) };
//     piece_sets[@intFromEnum(PieceColor.white)].pieces[1] =
//         Piece{ .type = .pawn, .pos = boardToMemCoords('b', 1) };

//     piece_sets[@intFromEnum(PieceColor.black)].pieces[0] =
//         Piece{ .type = .pawn, .pos = boardToMemCoords('a', 2) };
//     piece_sets[@intFromEnum(PieceColor.black)].pieces[1] =
//         Piece{ .type = .pawn, .pos = boardToMemCoords('b', 2) };
// }

// fn initBoard(board: []PieceHandle, piece_sets: []PieceSet) void {
//     for (board) |*piece_handle|
//         piece_handle.* = PieceHandle{ .set_color = PieceColor.none, .piece_index = null };

//     for (0..2) |set_color_index| {
//         for (piece_sets[set_color_index].pieces, 0..) |piece, piece_index| {
//             board[piece.pos[0] * board_dim + piece.pos[1]] = PieceHandle{
//                 .set_color = @enumFromInt(set_color_index),
//                 .piece_index = @intCast(piece_index),
//             };
//         }
//     }
// }

// fn handleFromCoords(board: []PieceHandle, coords: @Vector(2, u8)) *PieceHandle {
//     if (@reduce(.And, coords < @as(@Vector(2, u8), @splat(board_dim))))
//         return @ptrCast(board.ptr + coords[0] * board_dim + coords[1]);
//     unreachable;
// }

// fn pieceFromHandle(piece_handle: PieceHandle, piece_sets: []PieceSet) ?*Piece {
//     var result: ?*Piece = null;
//     if (piece_handle.piece_index != null)
//         result = &piece_sets[@intFromEnum(piece_handle.set_color)].pieces[piece_handle.piece_index.?];
//     return result;
// }

// fn validMoves(
//     ally: std.mem.Allocator,
//     board: []PieceHandle,
//     piece_sets: []PieceSet,
//     mem_coords: @Vector(2, u8),
//     move_list: *std.ArrayList(MoveNode),
// ) !void {
//     const piece_handle = handleFromCoords(board, mem_coords).*;
//     const piece = pieceFromHandle(piece_handle, piece_sets) orelse unreachable;

//     switch (piece.type) {
//         .pawn => { // TODO(caleb): En passant
//             for ([_]@Vector(2, i8){
//                 @Vector(2, i8){ -1, 1 }, @Vector(2, i8){ -1, -1 }, // Pawn x pawn
//             }) |d_pos_white| {
//                 // NOTE(caleb): White pawns move "upward" (-1) in memory. If black invert direction.
//                 var d_pos = d_pos_white;
//                 if (piece_handle.set_color == .black) d_pos[0] *= -1;
//                 const pos: @Vector(2, i8) = @bitCast(piece.pos);

//                 if (@reduce(.And, (pos + d_pos) < @as(@Vector(2, i8), @splat(board_dim))) and
//                     @reduce(.And, (pos + d_pos) >= @as(@Vector(2, i8), @splat(0))) and
//                     handleFromCoords(board, @bitCast(pos + d_pos)).set_color != piece_handle.set_color and
//                     handleFromCoords(board, @bitCast(pos + d_pos)).set_color != .none)
//                 {
//                     try move_list.append(MoveNode{
//                         .from_pos = @bitCast(pos),
//                         .to_pos = @bitCast(pos + d_pos),
//                         .edges = std.ArrayList(MoveNode).init(ally),
//                     });
//                 }
//             }

//             // for ([_]@Vector(2, i8){
//             //     @Vector(2, i8){ -1, 0 }, //@Vector(2, i8){ -2, 0 }, // Forward!! TODO(caleb): Handle +2 off start rank
//             // }) |d_pos_white| {
//             //     var d_pos = d_pos_white;
//             //     if (piece_handle.set_color == .black) d_pos[0] *= -1;
//             //     const row_index: i8 = @intCast(piece.pos[0]);
//             //     const col_index: i8 = @intCast(piece.pos[1]);
//             //     if (row_index + d_pos[0] < board_dim and row_index + d_pos[0] >= 0 and
//             //         col_index + d_pos[1] < board_dim and col_index + d_pos[1] >= 0 and
//             //         board[@intCast((row_index + d_pos[0]) * board_dim + col_index + d_pos[1])].set_color == .none)
//             //     {
//             //         const new_board_coords = memToBoardCoords(@intCast(row_index + d_pos[0]), @intCast(col_index + d_pos[1]));
//             //         try stdout.print("{c},{d}\n", .{ new_board_coords[0], new_board_coords[1] });
//             //     }
//             // }
//         },
//         // .night => {
//         //     for ([_]@Vector(2, i8){
//         //         @Vector(2, i8){ -2, 1 }, @Vector(2, i8){ -2, -1 }, // Up
//         //         @Vector(2, i8){ 1, 2 }, @Vector(2, i8){ -1, 2 }, // Right
//         //         @Vector(2, i8){ 2, 1 }, @Vector(2, i8){ 2, -1 }, // Down
//         //         @Vector(2, i8){ 1, -2 }, @Vector(2, i8){ -1, -2 }, // Left
//         //     }) |d_pos| {
//         //         const row_index: i8 = @intCast(piece.pos[0]);
//         //         const col_index: i8 = @intCast(piece.pos[1]);
//         //         if (row_index + d_pos[0] < 8 and row_index + d_pos[0] >= 0 and
//         //             col_index + d_pos[1] < 8 and col_index + d_pos[1] >= 0 and
//         //             board[@intCast((row_index + d_pos[0]) * 8 + col_index + d_pos[1])].set_color != piece_handle.set_color)
//         //         {
//         //             const new_board_coords = memToBoardCoords(@intCast(row_index + d_pos[0]), @intCast(col_index + d_pos[1]));
//         //             try stdout.print("{c},{d}\n", .{ new_board_coords[0], new_board_coords[1] });
//         //         }
//         //     }
//         // },
//         // .bishop => {
//         //     for ([_]@Vector(2, i8){
//         //         @Vector(2, i8){ -1, -1 }, // Top left
//         //         @Vector(2, i8){ -1, 1 }, // Top right
//         //         @Vector(2, i8){ 1, -1 }, // Bottom left
//         //         @Vector(2, i8){ 1, 1 }, // Bottom right
//         //     }) |d_pos| {
//         //         var row_index: i8 = @intCast(piece.pos[0]);
//         //         var col_index: i8 = @intCast(piece.pos[1]);
//         //         while ((row_index + d_pos[0] < 8 and row_index + d_pos[0] >= 0) and
//         //             (col_index + d_pos[1] < 8 and col_index + d_pos[1] >= 0) and
//         //             (board[@intCast((row_index + d_pos[0]) * 8 + col_index + d_pos[1])].set_color != piece_handle.set_color))
//         //         {
//         //             const new_board_coords = memToBoardCoords(@intCast(row_index + d_pos[0]), @intCast(col_index + d_pos[1]));
//         //             try stdout.print("{c},{d}\n", .{ new_board_coords[0], new_board_coords[1] });

//         //             if (board[@intCast((row_index + d_pos[0]) * 8 + col_index + d_pos[1])].set_color != .none)
//         //                 break;

//         //             row_index += d_pos[0];
//         //             col_index += d_pos[1];
//         //         }
//         //     }
//         // },
//         else => unreachable,
//     }
// }

/// Updates a piece's pos and it's corosponding piece handle.
// fn movePiece(
//     board: []PieceHandle,
//     piece_sets: []PieceSet,
//     from_pos: @Vector(2, u8),
//     to_pos: @Vector(2, u8),
// ) void {
//     var piece_handle = handleFromCoords(board, from_pos);
//     var piece = pieceFromHandle(piece_handle.*, piece_sets);
//     if (piece == null) {
//         const board_coords = memToBoardCoords(from_pos[0], from_pos[1]);
//         std.debug.print("No piece at ({c},{d})\n", .{ board_coords[0], board_coords[1] });
//         unreachable;
//     }
//     piece.?.pos = to_pos;
//     board[to_pos[0] * board_dim + to_pos[1]] = piece_handle.*;
//     piece_handle.* = PieceHandle{ .piece_index = null, .set_color = .none };
// }

fn drawBitboard(stdout: anytype, bb: Bitboard) !void {
    try stdout.writeAll("  +");
    for (0..board_dim * 3) |_|
        try stdout.writeByte('-');
    try stdout.writeAll("+\n");

    var row_index: i8 = board_dim - 1;
    while (row_index > -1) : (row_index -= 1) {
        try stdout.print("{d} |", .{board_dim - row_index});
        var col_index: i8 = board_dim - 1;
        while (col_index > -1) : (col_index -= 1) {
            try stdout.writeByte(' ');
            if (bb & (@as(Bitboard, 1) << @intCast(row_index * board_dim + col_index)) > 0) {
                try stdout.writeByte('1');
            } else {
                try stdout.writeByte('0');
            }
            try stdout.writeByte(' ');
        }
        try stdout.writeAll("|\n");
    }

    try stdout.writeAll("  +");
    for (0..board_dim * 3) |_|
        try stdout.writeByte('-');
    try stdout.writeAll("+\n");

    try stdout.writeAll("   ");
    for (0..board_dim) |col_index|
        try stdout.print(" {c} ", .{'a' + @as(u8, @intCast(col_index))});
    try stdout.writeByte('\n');
}

fn drawBoard(stdout: anytype, bitboards: []Bitboard) !void {
    var printable_board: [board_dim * board_dim]?Piece = undefined;
    for (&printable_board) |*p| p.* = null;

    const black_start = @divExact(bitboards.len, 2);
    for (bitboards, 0..) |bb, board_index| {
        var row_index: i8 = board_dim - 1;
        while (row_index > -1) : (row_index -= 1) {
            var col_index: i8 = board_dim - 1;
            while (col_index > -1) : (col_index -= 1) {
                if (bb & (@as(Bitboard, 1) << @intCast(row_index * board_dim + col_index)) > 0) {
                    printable_board[@intCast(row_index * board_dim + col_index)] = Piece{
                        .type = if (board_index < black_start) @enumFromInt(board_index) else @enumFromInt(board_index - black_start),
                        .color = if (board_index < black_start) .white else .black,
                    };
                }
            }
        }
    }

    try stdout.writeAll("  +");
    for (0..board_dim * 3) |_|
        try stdout.writeByte('-');
    try stdout.writeAll("+\n");

    var row_index: i8 = board_dim - 1;
    while (row_index > -1) : (row_index -= 1) {
        try stdout.print("{d} |", .{row_index + 1});
        var col_index: i8 = board_dim - 1;
        while (col_index > -1) : (col_index -= 1) {
            const piece = printable_board[@intCast(row_index * board_dim + col_index)];
            try stdout.writeByte(' ');
            if (piece == null) {
                try stdout.writeByte('.');
            } else {
                switch (piece.?.color) {
                    .white => try stdout.writeByte(ascii.toUpper(@tagName(piece.?.type)[0])),
                    .black => try stdout.writeByte(@tagName(piece.?.type)[0]),
                }
            }
            try stdout.writeByte(' ');
        }
        try stdout.writeAll("|\n");
    }

    try stdout.writeAll("  +");
    for (0..board_dim * 3) |_|
        try stdout.writeByte('-');
    try stdout.writeAll("+\n");

    try stdout.writeAll("   ");
    for (0..board_dim) |col_index|
        try stdout.print(" {c} ", .{'a' + @as(u8, @intCast(col_index))});
    try stdout.writeByte('\n');
}

// const MoveNode = struct { // From pos is recorded by parent node.
//     from_pos: @Vector(2, u8),
//     to_pos: @Vector(2, u8),
//     edges: std.ArrayList(MoveNode),
// };

fn initBitboards(bitboards: []Bitboard) void {
    for (bitboards) |*bit_board| bit_board.* = 0;

    // White bitboard(s)
    bitboards[0] |= (1 << (0 * board_dim + 0));
    bitboards[0] |= (1 << (0 * board_dim + 1));

    // Black bitboard(s)
    bitboards[1] |= (1 << (1 * board_dim + 0));
    bitboards[1] |= (1 << (1 * board_dim + 1));
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var backing_buffer = try std.heap.page_allocator.alloc(u8, 1024 * 5);
    var fb = std.heap.FixedBufferAllocator.init(backing_buffer);
    var arena = std.heap.ArenaAllocator.init(fb.allocator());
    const ally = arena.allocator();
    _ = ally;

    var bitboards: [2]Bitboard = undefined;

    initBitboards(&bitboards);

    try drawBitboard(stdout, bitboards[0]);
    try drawBoard(stdout, &bitboards);

    // try initPieceSetsSmol(&piece_sets);
    // initBoard(&board, &piece_sets);

    // const arena_state = arena.state; // Begin tmp mem

    // var move_root = try ally.create(MoveNode);
    // move_root.* = MoveNode{
    //     .from_pos = undefined,
    //     .to_pos = undefined,
    //     .edges = std.ArrayList(MoveNode).init(ally),
    // };
    // var current_node = move_root;

    // for (0..move_depth) |depth_index| {
    //     _ = depth_index;
    //     for (piece_sets, 0..) |piece_set, set_index| {
    //         _ = set_index;
    //         // try stdout.print("{s} possible moves:\n", .{@tagName(@as(PieceColor, @enumFromInt(set_index)))});
    //         for (piece_set.pieces) |p| {
    //             try validMoves(ally, &board, &piece_sets, p.pos, &current_node.edges);
    //         }

    //         for (current_node.edges.items) |move_node| {
    //             // TODO(caleb): Also reocrd piece handle, also this logic is stupid...
    //             var to_piece: Piece = undefined;
    //             const to_piece_ptr = pieceFromHandle(handleFromCoords(&board, move_node.to_pos), &piece_sets);
    //             if (to_piece_ptr != null)
    //                 to_piece = to_piece_ptr.?.*;

    //             movePiece(&board, &piece_sets, move_node.from_pos, move_node.to_pos);

    //             // Gen moves for other piece set
    //             genMoves(ally, &board, &piece_sets, move_node);

    //             movePiece(&board, &piece_sets, move_node.to_pos, move_node.from_pos);
    //             if (to_piece_ptr != null) {
    //                 to_piece_ptr.?.* = to_piece;
    //                 // movePiece(&board, &piece_sets, )
    //             }

    //             // TODO(caleb): Restore board state
    //         }
    //     }
    // }

    // for (move_root.edges.items) |e| {
    //     try stdout.print("{?} => {?}\n", .{ e.from_pos, e.to_pos });
    // }

    // arena.state = arena_state; // End tmp mem

    // try drawBoard(stdout, &board, &piece_sets);
}
