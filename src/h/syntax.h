/*  $Id$

    Part of XPCE
    Designed and implemented by Anjo Anjewierden and Jan Wielemaker
    E-mail: jan@swi.psy.uva.nl

    Copyright (C) 1992 University of Amsterdam. All rights reserved.
*/

#ifndef GLOBAL
#define GLOBAL extern
#endif

NewClass(syntax_table)
  Name		name;			/* Name of this table */
  Int		size;			/* Size of the table (256) */
  Regex		sentence_end;		/* End-Of-Sentence */
  Regex		paragraph_end;		/* End-Of-Pargraph */
  ushort       *table;			/* Type-flags */
  char	       *context;		/* Context info */
End;

#define makeCFlag(n)	(1 << (n-1))

#define LC	makeCFlag(1)		/* Lower case letter */
#define UC	makeCFlag(2)		/* Upper case letter */
#define DI	makeCFlag(3)		/* Digit */
#define WS	makeCFlag(4)		/* Word separator (in symbol) */
#define SY	makeCFlag(5) 		/* Other symbol-characters */
#define OB	makeCFlag(6)    	/* Open Brace (context: close) */
#define CB	makeCFlag(7)    	/* Close Brace (context: open) */
#define EL	makeCFlag(8)    	/* Ends Line */
#define BL	makeCFlag(9)    	/* Blank */
#define QT	makeCFlag(10)   	/* String quote (context: escape) */
#define PU	makeCFlag(11)		/* Punctuation */
#define EB	makeCFlag(12)		/* End Buffer/string */
#define CS	makeCFlag(13)		/* Comment-start (context: 2nd char) */
#define CE	makeCFlag(14)  		/* Comment-end (context: 2nd char) */

#define AN	(LC|UC|DI|WS|SY)	/* General symbol-character */

		/********************************
		*       CHARACTER TYPES		*
		********************************/

#define streq(s, t)	((s) && (t) && (strcmp((s), (t)) == 0))

#define META_OFFSET		(1L<<16)

#define EOS	0			/* end of string */
#define ESC	27			/* char escape */
#define TAB	9			/* tab character */
#define DEL	127			/* delete character */
#define Control(x) (x & 037)
#define Meta(x)    (x + META_OFFSET)

GLOBAL SyntaxTable DefaultSyntaxTable;	/* Systems default table */
extern ushort char_flags[];		/* Initial flags table */
extern ushort syntax_spec_code[];	/* Char --> syntax (for \sC regex) */
extern char  char_context[];		/* Initial context table */

#define islower(c)		(char_flags[(unsigned int)(c)] & LC)
#define isupper(c)		(char_flags[(unsigned int)(c)] & UC)
#define isdigit(c)		(char_flags[(unsigned int)(c)] & DI)
#define isopenbrace(c)		(char_flags[(unsigned int)(c)] & OB)
#define isclosebrace(c)		(char_flags[(unsigned int)(c)] & CB)
#define isendsline(c)		(char_flags[(unsigned int)(c)] & EL)
#define isblank(c)		(char_flags[(unsigned int)(c)] & BL)
#define islayout(c)		(char_flags[(unsigned int)(c)] & (BL|EL))
#define isquote(c)		(char_flags[(unsigned int)(c)] & QT)
#define issymbol(c)		(char_flags[(unsigned int)(c)] & SY)
#define iswordsep(c)		(char_flags[(unsigned int)(c)] & WS)

#define isalnum(c)		(char_flags[(unsigned int)(c)] & AN)
#define isletter(c)		(char_flags[(unsigned int)(c)] & (LC|UC))
#define ischtype(c, tp)		(char_flags[(unsigned int)(c)] & (tp))

#define ismatching(c1, c2)      (char_context[(unsigned int)(c1)] == (c2))
#define isstringescape(q, e)	(char_context[q] == (e))

		/********************************
		*         TABLE VERSIONS	*
		********************************/

#define tislower(t, c)		((t)->table[(unsigned int)(c)] & LC)
#define tisupper(t, c)		((t)->table[(unsigned int)(c)] & UC)
#define tisdigit(t, c)		((t)->table[(unsigned int)(c)] & DI)
#define tisopenbrace(t, c)	((t)->table[(unsigned int)(c)] & OB)
#define tisclosebrace(t, c)	((t)->table[(unsigned int)(c)] & CB)
#define tisendsline(t, c)	((t)->table[(unsigned int)(c)] & EL)
#define tisblank(t, c)		((t)->table[(unsigned int)(c)] & BL)
#define tislayout(t, c)		((t)->table[(unsigned int)(c)] & (BL|EL))
#define tisquote(t, c)		((t)->table[(unsigned int)(c)] & QT)
#define tissymbol(t, c)		((t)->table[(unsigned int)(c)] & SY)
#define tiswordsep(t, c)	((t)->table[(unsigned int)(c)] & WS)

#define tisalnum(t, c)		((t)->table[(unsigned int)(c)] & AN)
#define tisletter(t, c)		((t)->table[(unsigned int)(c)] & (LC|UC))
#define tischtype(t, c, tp)	((t)->table[(unsigned int)(c)] & (tp))

#define tismatching(t, c1, c2)  ((t)->context[c1] == (c2))
#define tisstringescape(t,q,e)	((t)->context[q] == (e))

#define tiscommentstart(t, c)	((t)->table[(unsigned int)(c)] & CS && \
				 !(t)->context[(unsigned int)(c)])
#define tiscommentend(t, c)	((t)->table[(unsigned int)(c)] & CE && \
				 !(t)->context[(unsigned int)(c)])
#define tiscommentstart1(t, c)	((t)->table[(unsigned int)(c)] & CS && \
				 (t)->context[(unsigned int)(c)] & 1)
#define tiscommentend1(t, c)	((t)->table[(unsigned int)(c)] & CE && \
				 (t)->context[(unsigned int)(c)] & 4)
#define tiscommentstart2(t, c)	((t)->table[(unsigned int)(c)] & CS && \
				 (t)->context[(unsigned int)(c)] & 2)
#define tiscommentend2(t, c)	((t)->table[(unsigned int)(c)] & CE && \
				 (t)->context[(unsigned int)(c)] & 8)


		/********************************
		*        CASE CONVERSION	*
		********************************/

extern char  char_lower[];
extern char  char_upper[];

#define tolower(c)		(char_lower[(unsigned int)(c)])
#define toupper(c)		(char_upper[(unsigned int)(c)])

		/********************************
		*     HOST-LANGUAGE SYMBOLS	*
		********************************/

GLOBAL struct
{ int	uppercase;			/* keywords mapped to uppercase */
  char	word_separator;			/* current word separator */
} syntax;

