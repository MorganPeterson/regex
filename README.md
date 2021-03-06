
# NFA Regex

## Intro

This program is based entirely on [Russ Cox's](https://swtch.com/~rsc/)
article [Regular Expression Matching Can Be Simple And Fast
(but is slow in Java, Perl, PHP, Python, Ruby, ...)](
https://swtch.com/~rsc/regexp/regexp1.html).

This is my attempt at implementing it in zig.

>main
```zig
const std = @import("std");

//<<state_struct>>

//<<frag_struct>>

//<<ptrlist_union>>

//<<macro_helpers>>

//<<ptrlist_helper_functions>>

//<<postfix_loop>>

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}

```

### NFA

This is our representation of our NFA in the form of a linked collection of
State structures.

Each state will exist in one of three states:
1. `c < 256` - a character
2. `c == 256` - a split
3. `c == 257` - a match

>state_struct
```zig
const StateType = enum(i32) {
    Match = 256,
    Split = 257,
};

const State = struct {
    c: i32, out: ?*State, out1: ?*State, lastlist: int32
};
```

### NFA fragments

The compiler will need to maintain a stack of computed NFA fragments. This is
that fragment as a structure.

>frag_struct
```zig
const Frag = struct {
    start: ?*State, out: ?*Ptrlist
};
```

### Pointer List

Out pointers in a list are always uninitialized. We use those pointers as
storage for the PtrLists

>ptrlist_union
```zig
const Ptrlist = union {
    next: ?*Ptrlist, s: ?*State
};
```

### Pointer List helper functions

1. list1 creates a new pointer list containing a single pointer outp.
2. append concatenates two pointer lists, returning the result.
3. patch connects the dangling pointers in the pointer list l to the state s:
   it sets outp = s for each pointer outp in l.

>ptrlist_helper_functions
```zig
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
```

### Macros

In C we would write these as macros, but zig doesn't not have a mechanisim for
macros so we write these helper functions.

1. pop to move the stack pointer up one
2. push to add a state to the stack

>macro_helpers
```zig
fn push(stack: *Frag, s: *State) void {
    *stack += 1;
    *stack = s;
}

fn pop(stack: *Frag) void {
    *stack -= 1;
}
```

### Compile the postfix expression

Here we have a function that does one loop through the postfix expression
and compiles. At the end, we patch in matching state and that completes the
NFA.

These are the specific compilation cases.

1. '.': catenation
2. '|': alternation
3. '?': zero or one
4. '\*': zero or more
5. '+': 1 or more
6 else: literal character

>postfix_loop
```zig
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
```
