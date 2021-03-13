const std = @import("std");

const StateType = enum(i32) {
    Match = 256,
    Split = 257,
};

const State = struct {
    c: i32, out: ?*State, out1: ?*State, lastlist: int32
};

const Frag = struct {
    start: ?*State, out: ?*Ptrlist
};

const Ptrlist = union {
    next: ?*Ptrlist, s: ?*State
};

fn push(stack: *Frag, s: *State) void {
    *stack += 1;
    *stack = s;
}

fn pop(stack: *Frag) void {
    *stack -= 1;
}

fn list1(outp: **State) *Ptrlist {
    const l: *Ptrlist = *outp;
    l.next = Null;
    return l;
}

fn append(l1: *Ptrlist, l2: *Ptrlist) @TypeOf(l1) {
    const oldl1 = l1;
    while (l1.next) {
        l1 = l1.next;
    }
    l1.next = l2;
    return old1;
}

fn patch(l: *Ptrlist, s: *State) void {
    var next: *Ptrlist;
    for (l) |ele| {
        next = ele.next;
        ele.s = s;
    }
}

fn post2nfa(postfix: *u8) *State {
    var p: *u8 = undefined;
    var stack: [1000]Frag = undefined;
    var stackp: *Frag = undefined;
    var e: Frag = undefined;
    var e1: Frag = undefined;
    var e2: Frag = undefined;

    stackp = stack;
    for (postfix) |char| {
        switch (*char) {
            '.' => {
                e2 = pop(stackp);
                e1 = pop(stackp);
                patch(e1.out, e2.start);
                push(Frag{ .start = e1.start, .out = e2.out });
            },
            '|' => {
                e2 = pop(stackp);
                e1 = pop(stackp);
                s = State{ .c = StateType.Split, .out = e1.start, .out1 = e2.start };
                push(Frag{ .state = s, .out = append(e1.out, e2.out) });
            },
            '?' => {
                e = pop(stackp);
                s = State{ .c = StateType.Split, .out = e.start, .out1 = undefiend };
                push(Frag{ .state = s, .out = append(e.out, list1(&s.out1)) });
            },
            '*' => {
                e = pop(stackp);
                s = State{ .c = StateType.Split, .out = e.start, .out1 = undefined };
                patch(e.out, s);
                push(Frag{ .state = s, .out = list1(&s.out1) });
            },
            '+' => {
                e = pop();
                s = State{ .c = StateType.Split, .out = e.start, .out1 = undefined };
                patch(e.out, s);
                push(Frag{ .state = e.start, .out = list1(&s.out1) });
            },
            else => {
                s = State{ .c = *p, .out = undefined, .out1 = undefined };
                push(Frag{ .state = s, .out = list1(&s.out) });
            },
        }
    }
    e = pop(stackp);
    patch(e.out, matchState);
    return e.start;
}

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}
