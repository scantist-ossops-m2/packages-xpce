/*  $Id$

    Part of XPCE
    Designed and implemented by Anjo Anjewierden and Jan Wielemaker
    E-mail: jan@swi.psy.uva.nl

    Copyright (C) 1992 University of Amsterdam. All rights reserved.
*/



:- module(man_class_hierarchy,
	  [
	  ]).

:- use_module(library(pce)).
:- use_module(util).
:- require([ forall/2
	   , get_chain/3
	   , member/2
	   , send_list/3
	   ]).


:- pce_begin_class(man_class_hierarchy, man_frame,
		   "Display hiearchy of classes").

variable(selection,		node*,		get,
	 "Currently selected node").
variable(create_message,	code,		get,
	 "Message used to trap new classes").


initialise(CH, Manual:man_manual) :->
	"Create from manual"::
	send(CH, send_super, initialise, Manual, 'Class Hierarchy'),
	send(CH, slot, create_message,
	     new(Msg, message(CH, created_class, @arg2))),
	send(@class_class, created_message, Msg),

	send(CH, append, new(P, picture)),
	new(D, dialog),
	send(D, below, P),
	fill_dialog(D),
	fill_picture(P),
	send(P, recogniser, handler(keyboard, message(@event, post, D))),
	send(CH, expand_node, CH?tree?root).


unlink(CH) :->
	(   send(@class_class?created_messages, delete, CH?create_message)
	;   true
	), !,
	send(CH, send_super, unlink).


fill_dialog(D) :-
	new(CH, D?frame),
	send(D, append,
	     new(TI, text_item(class, '', message(CH, focus, @arg1)))),
	send(TI, type, class),
	send(TI, value_set, ?(@prolog, expand_classname, @arg1)),
	send(D, append, button(apply,
			       and(message(D, apply),
				   message(@receiver, active, @off)))),
	send(D, append, button(help, message(CH, help))),
	send(D, append, button(quit, message(CH, quit))),
	
	send(D?apply_member, active, @off),
	send(D, default_button, apply).

expand_classname(Prefix, Classes) :-
	new(Classes, chain),
	send(@classes, for_all,
	     if(message(@arg2?name, prefix, Prefix),
		message(Classes, append, @arg2))).


:- pce_global(@man_hierarchy_popup, make_popup).

make_popup(P) :-
	new(CH, @arg1?frame),
	new(Manual, CH?manual),
	new(Selection, Manual?selection),
	Node = @arg1,
	new(Class, Node?context),
	new(P, popup),
	new(HasSubClasses, when(Class?sub_classes,
				Class?sub_classes?size,
				0) > 0),

	send_list(P, append,
	     [ menu_item(select,
			 message(CH, request_selection, Class, @on),
			 @default, @off,
			 Node?inverted == @off)
	     , menu_item(focus,
			 message(CH, request_tool_focus, Class),
			 @default, @on)
	     , menu_item(expand,
			 block(message(CH, expand_node, Node),
			       message(CH, normalise_node, Node)),
			 @default, @off,
			 and(message(Node?sons, empty),
			     HasSubClasses))
	     , menu_item(expand_tree,
			 block(message(CH, expand_tree, Node),
			       message(CH, normalise_node, Node)),
			 @default, @off, HasSubClasses)
	     , menu_item(collapse_node,
			 message(CH, collapse_node, Node),
			 @default, @on,
			 not(message(Node?sons, empty)))
	     , menu_item(source,
			 message(CH, request_source, Class),
			 @default, @on)
	     ]),
	ifmaintainer(send_list(P, append,
	     [ menu_item(relate,
			 message(CH, request_relate, Class),
			 @default, @on,
			 and(Manual?edit_mode  == @on,
			     Selection \== @nil,
			     Selection \== Class,
			     not(message(Selection, man_related,
					 see_also, Class))))
	     ])).


fill_picture(P) :-
	create_node(@object_class, Root),
	send(P, display, new(T, tree(Root))),

	send_list(T, node_handler,
		  [ click_gesture(left, '', single,
				  message(P?frame, request_selection,
					  @receiver?context, @off))
		  , click_gesture(left, '', double,
				  message(P?frame, request_selection,
					  @receiver?context, @on))
		  , popup_gesture(@man_hierarchy_popup)
		  ]).


		/********************************
		*          FIND OBJECTS		*
		********************************/

tree(CH, Tree) :<-
	"Displayed tree"::
	get(CH?picture_member, tree_member, Tree).


node(CH, Class, Node) :<-
	"Node displaying class"::
	get(CH, tree, Tree),
	get(Class, name, Name),
	get(Tree?root, find, Name == @arg1?image?string?value, Node).


		/********************************
		*             FOCUS		*
		********************************/

focus(CH, Class:class) :->
	"Show indicated class"::
	ensure_displayed(CH, Class, Node),
	send(CH, selected, Class),
	send(CH?picture_member, normalise, Node).

ensure_displayed(CH, Class, Node) :-
	get(CH, node, Class, Node), !.
ensure_displayed(CH, Class, Node) :-
	get(Class, super_class, Super),
	ensure_displayed(CH, Super, SuperNode),
	send(CH, expand_node, SuperNode),
	get(CH, node, Class, Node).


		/********************************
		*           SELECTION		*
		********************************/

selected(CH, Obj:object*) :->
	"Set selection to specific class"::
	get(@pce, convert, Obj, 'class*', Class),
	send(CH, slot, selection, @nil),
	send(CH?tree, for_all,
	     if(@arg1?context == Class,
		block(message(@arg1?image, inverted, @on),
		      message(CH, slot, selection, @arg1)),
		message(@arg1?image, inverted, @off))).


release_selection(CH) :->
	send(CH, selected, @nil).


		/********************************
		*          EXPAND TREE		*
		********************************/

expand_node(_CH, Node:node) :->
	"Expand node of the tree"::
	(   send(Node?sons, empty)
	->  node_to_class(Node, Class),
	    (	get(Class, sub_classes, SubClasses)
	    ->	new(Subs, chain),
		send(Subs, merge, SubClasses),
		send(Subs, sort),
		send(Subs, for_all,
		     message(@prolog, add_subnode, Node, @arg1))
	    ;	true
	    )
	;   true
	).


add_subnode(Node, Class) :-
	create_node(Class, Sub),
	send(Node, son, Sub).


create_node(Class, Node) :-
	(   get(Class?sub_classes, size, Size),
	    Size > 0
	->  Font = font(helvetica, bold, 12)
	;   Font = font(helvetica, roman, 12)
	),
	new(Node, node(text(Class?name, left, Font))),
	send(Node, attribute, attribute(context, Class)).


expand_tree(CH, Node:node) :->
	"Expand entire subtree"::
	send(CH, expand_node, Node),
	send(Node?sons, for_all, message(CH, expand_tree, @arg1)).
	

expand_selection(CH) :->
	"Expand selected node"::
	get(CH, selection, Node),
	(   Node \== @nil
	->  send(CH, expand_node, Node)
	;   send(@display, inform, 'First make a selection')
	).


collapse_node(_CH, Node:node) :->
	"Destroy subnodes"::
	send(Node?sons, for_all, message(@arg1, delete_tree)).


normalise_node(_CH, Node:node) :->
	"Normalise for the subtree of Node"::
	new(Ch, chain),
	send(Node, for_all, message(Ch, append, @arg1?image)),
	send(Node?window, normalise, Ch),
	send(Ch, done).


		/********************************
		*        TRAP NEW CLASSES	*
		********************************/

created_class(CH, Class) :->
	"Handle a new class"::
	(   get(Class, super_class, Super),
	    get(CH, node, Super, Node)
	->  send(Node, font, font(helvetica, bold, 12)),
	    (   send(Node?sons, empty)
	    ->  true
	    ;   add_subnode(Node, Class)		  % TBD: alphabetical
	    )
	;   true
	).


		/********************************
		*        MISCELLANEOUS		*
		********************************/

node_to_class(Node, Class) :-
	get(Node, context, Class).

:- pce_end_class.
