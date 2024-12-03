/*  $Id$

    Part of XPCE

    Author:  Jan Wielemaker and Anjo Anjewierden
    E-mail:  jan@swi.psy.uva.nl
    WWW:     http://www.swi.psy.uva.nl/projects/xpce/
    Copying: GPL-2.  See the file COPYING or http://www.gnu.org

    Copyright (C) 1990-2001 SWI, University of Amsterdam. All rights reserved.
*/


:- module(pce_operator,
	[ push_operators/1
	, pop_operators/0
	]).


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Often, one  wants to define  operators to improve  the  readibility of
some very  specific code.  Operators in  Prolog are global objects and
changing operators changes syntax  and  possible semantics of existing
sources.   For this   reason   it is   desirable to  reset    operator
declarations after   the code that  needs  them   has been read.  This
module defines a  rather cruel  method to do  this.  In  the future it
might be better to  limit operator definitions  to  the file they  are
declated (like style_check/1).

Usage:

:- push_operators(
	[ op(900, fx, hello_world)
	, op(600, xf, *)
	]).
	
hello_world World :-
	....

:- pop_operators.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

:- dynamic
	operator_stack/1.

push_operators(New) :-
	undo_operators(New, Undo),
	set_operators(New),
	asserta(operator_stack(Undo)).

pop_operators :-
	retract(operator_stack(Undo)), !,
	set_operators(Undo).

set_operators([]).
set_operators([op(P,T,A)|R]) :-
	op(P, T, A),
	set_operators(R).

undo_operators([], []).
undo_operators([O0|T0], [U0|T]) :-
	undo_operator(O0, U0),
	undo_operators(T0, T).

undo_operator(op(_P, T, N), op(OP, OT, N)) :-
	current_op(OP, OT, N),
	same_op_type(T, OT), !.
undo_operator(op(P, T, [H|R]), [OH|OT]) :- !,
	undo_operator(op(P, T, H), OH),
	undo_operator(op(P, T, R), OT).
undo_operator(op(_, _, []), []) :- !.
undo_operator(op(_P, T, N), op(0, T, N)).
	
same_op_type(T, OT) :-
	op_type(T, Type),
	op_type(OT, Type).

op_type(fx,  prefix).
op_type(fy,  prefix).
op_type(xfx, infix).
op_type(xfy, infix).
op_type(yfx, infix).
op_type(yfy, infix).
op_type(xf,  postfix).
op_type(yf,  postfix).