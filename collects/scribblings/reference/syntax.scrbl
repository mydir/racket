#reader(lib "docreader.ss" "scribble")
@require["mz.ss"]

@define[cvt (schemefont "CVT")]

@title[#:tag "mz:syntax" #:style 'toc]{Core Syntactic Forms}

This section describes core syntax forms that apear in a fully
expanded expression, plus a few closely-related non-core forms.

@local-table-of-contents[]

@subsubsub*section{Notation}

Each syntactic form is described by a BNF-like notation that describes
a combination of (syntax-wrapped) pairs, symbols, and other data (not
a sequence of characters). These grammatical specifications are shown
as follows:

@specsubform[(#, @schemekeywordfont{some-form} id ...)]

Within such specifications,

@itemize{

 @item{@scheme[...] indicates zero or more
       repetitions of the preceding datum.}

 @item{@scheme[...+] indicates one or
       more repetitions of the preceding datum.}

 @item{italic meta-identifiers play the role of non-terminals; in
       particular,

      @itemize{

        @item{a meta-identifier that ends in @scheme[_id] stands for an
              identifier.}

        @item{a meta-identifier that ends in @scheme[_keyword] stands
              for a keyword.}

        @item{a meta-identifier that ends with @scheme[_expr] stands
              for a sub-form that is expanded as an expression.}

        @item{A meta-identifier that ends with @scheme[_body] stands
              for a sub-form that is expanded in an
              internal-definition context (see
              @secref["mz:intdef-body"]).}

              }} }

@;------------------------------------------------------------------------
@section{Variable References and @scheme[#%top]}

@defform/none[id]{

Refers to a module-level or local binding, when @scheme[id] is
not bound as a transformer (see @secref["mz:expansion"]). At run-time,
the reference evaluates to the value in the location associated with
the binding.

When the expander encounters an @scheme[id] that is not bound by a
module-level or local binding, it converts the expression to @scheme[(#,
@schemeidfont{#%top} . id)] giving @schemeidfont{#%top} the lexical
context of the @scheme[id]; typically, that context refers to
@scheme[#%top].

@examples[
(define x 10)
x
(let ([x 5]) x)
((lambda (x) x) 2)
]}

@defform[(#%top . id)]{

Refers to a top-level definition that could bind @scheme[id],
even if @scheme[id] has a local binding in its context. Such
references are disallowed anywhere within a @scheme[module] form.

@examples[
(define x 12)
(let ([x 5]) (#%top . x))
]}

@;------------------------------------------------------------------------
@section[#:tag "mz:application"]{Procedure Applications and @scheme[#%app]}

@guideintro["guide:application"]{procedure applications}

@defform/none[(proc-expr arg ...)]{

Applies a procedure, when @scheme[proc-expr] is not an
identifier that has a transformer binding (see
@secref["mz:expansion"]).

More precisely, the expander converts this form to @scheme[(#,
@schemeidfont{#%app} proc-expr arg ...)], giving @schemeidfont{#%app}
the lexical context that is associated with the original form (i.e.,
the pair that combines @scheme[proc-expr] and its
arguments). Typically, the lexical context of the pair indicates the
procedure-application @scheme[#%app] that is described next.

@examples[
(+ 1 2)
((lambda (x #:arg y) (list y x)) #:arg 2 1)
]}

@defform[(#%app proc-expr arg ...)]{

Applies a procedure. Each @scheme[arg] is one of the following:

 @specsubform[arg-expr]{The resulting value is a non-keyword
                        argument.}

 @specsubform[(code:line keyword arg-expr)]{The resulting value is a
              keyword argument using @scheme[keyword]. Each
              @scheme[keyword] in the application must be distinct.}

The @scheme[proc-expr] and @scheme[_arg-expr]s are evaluated in order,
left to right. If the result of @scheme[proc-expr] is a procedure that
accepts as many arguments as non-@scheme[_keyword]
@scheme[_arg-expr]s, if it accepts arguments for all of the
@scheme[_keyword]s in the application, and if all required
keyword-based arguments are represented among the @scheme[_keyword]s
in the application, then the procedure is called with the values of
the @scheme[arg-expr]s. Otherwise, the @exnraise[exn:fail:contract].

The continuation of the procedure call is the same as the continuation
of the application expression, so the results of the procedure are the
results of the application expression.

The relative order of @scheme[_keyword]-based arguments matters only
for the order of @scheme[_arg-expr] evaluations; the arguments are
associated with argument variables in the applied procedure based on
the @scheme[_keyword]s, and not their positions. The other
@scheme[_arg-expr] values, in contrast, are associated with variables
according to their order in the application form.

@examples[
(#%app + 1 2)
(#%app (lambda (x #:arg y) (list y x)) #:arg 2 1)
(#%app cons)
]}


@;------------------------------------------------------------------------
@section[#:tag "mz:lambda"]{Procedure Expressions: @scheme[lambda] and @scheme[case-lambda]}

@guideintro["guide:lambda"]{procedure expressions}

@defform/subs[(lambda gen-formals body ...+)
              ([formals (id ...)
                        (id ...+ . rest-id)
                        rest-id]
               [gen-formals formals
                            (arg ...)
                            (arg ...+ . rest-id)]
               [arg id
                    [id default-expr]
                    (code:line keyword id)
                    (code:line keyword [id default-expr])])]{

Produces a procedure. The @scheme[gen-formals] determines the number of
arguments that the procedure accepts. It is either a simple
@scheme[formals] or one of the extended forms.

A simple @scheme[_formals] has one of the following three forms:

@specsubform[(id ...)]{ The procedure accepts as many non-keyword
       argument values as the number of @scheme[id]s. Each @scheme[id]
       is associated with an argument value by position.}

@specsubform[(id ...+ . rest-id)]{ The procedure accepts any number of
       non-keyword arguments greater or equal to the number of
       @scheme[id]s. When the procedure is applied, the @scheme[id]s
       are associated with argument values by position, and all
       leftover arguments are placed into a list that is associated to
       @scheme[rest-id].}

@specsubform[rest-id]{ The procedure accepts any number of non-keyword
       arguments. All arguments are placed into a list that is
       associated with @scheme[rest-id].}

Besides the three @scheme[formals] forms, a @scheme[gen-formals] can be
a sequence of @scheme[arg]s optionally ending with a
@scheme[rest-id]:

@specsubform[(arg ...)]{ Each @scheme[arg] has the following
       four forms:

        @specsubform[id]{Adds one to both the minimum and maximum
        number of non-keyword arguments accepted by the procedure. The
        @scheme[id] is associated with an actual argument by
        position.}

        @specsubform[[id default-expr]]{Adds one to the maximum number
        of non-keyword arguments accepted by the procedure. The
        @scheme[id] is associated with an actual argument by position,
        and if no such argument is provided, the @scheme[default-expr]
        is evaluated to produce a value associated with @scheme[id].
        No @scheme[arg] with a @scheme[default-expr] can appear
        before an @scheme[id] without a @scheme[default-expr] and
        without a @scheme[keyword].}

       @specsubform[(code:line keyword id)]{The procedure requires a
       keyword-based argument using @scheme[keyword]. The @scheme[id]
       is associated with a keyword-based actual argument using
       @scheme[keyword].}

       @specsubform[(code:line keyword [id default-expr])]{The
       procedure accepts a keyword-based using @scheme[keyword]. The
       @scheme[id] is associated with a keyword-based actual argument
       using @scheme[keyword], if supplied in an application;
       otherwise, the @scheme[default-expr] is evaluated to obtain a
       value to associate with @scheme[id].}

      The position of a @scheme[_keyword] @scheme[arg] in
      @scheme[gen-formals] does not matter, but each specified
      @scheme[_keyword] must be distinct.}

@specsubform[(arg ...+ . rest-id)]{ Like the previous case, but
       the procedure accepts any number of non-keyword arguments
       beyond its minimum number of arguments. When more arguments are
       provided than non-@scheme[_keyword] arguments among the
       @scheme[arg]s, the extra arguments are placed into a
       list that is associated to @scheme[rest-id].}

The @scheme[gen-formals] identifiers are bound in the @scheme[body]s. When
the procedure is applied, a new location is created for each
identifier, and the location is filled with the associated argument
value.

If any identifier appears in the @scheme[body]s that is not one of the
identifiers in @scheme[gen-formals], then it refers to the same location
that it would if it appeared in place of the @scheme[lambda]
expression. (In other words, variable reference is lexically scoped.)

When multiple identifiers appear in a @scheme[gen-formals], they must be
distinct according to @scheme[bound-identifier=?].

If the procedure procedure by @scheme[lambda] is applied to fewer or
more by-position or arguments than it accepts, to by-keyword arguments
that it does not accept, or without required by-keyword arguments, then
the @exnraise[exn:fail:contract].

The last @scheme[body] expression is in tail position with respect to
the procedure body.

@examples[
((lambda (x) x) 10)
((lambda (x y) (list y x)) 1 2)
((lambda (x [y 5]) (list y x)) 1 2)
(let ([f (lambda (x #:arg y) (list y x))])
 (list (f 1 #:arg 2)
       (f #:arg 2 1)))
]}

@defform[(case-lambda [formals body ...+] ...)]{

Produces a procedure. Each @scheme[[forms body ...+]]
clause is analogous to a single @scheme[lambda] procedure; applying
the @scheme[case-lambda]-generated procedure is the same as applying a
procedure that corresponds to one of the clauses---the first procedure
that accepts the given number of arguments. If no corresponding
procedure accepts the given number of arguments, the
@exnraise[exn:fail:contract].

Note that a @scheme[case-lambda] clause supports only
@scheme[formals], not the more general @scheme[_gen-formals] of
@scheme[lambda]. That is, @scheme[case-lambda] does not directly
support keyword and optional arguments.

@examples[
(let ([f (case-lambda
          [() 10]
          [(x) x]
          [(x y) (list y x)]
          [r r])])
  (list (f)
        (f 1)
        (f 1 2)
        (f 1 2 3)))
]}

@;------------------------------------------------------------------------
@section{Local Binding: @scheme[let], @scheme[let*], and @scheme[letrec]}

@defform*[[(let ([id val-expr] ...) body ...+)
           (let proc-id ([id init-expr] ...) body ...+)]]{

The first form evaluates the @scheme[val-expr]s left-to-right, creates
a new location for each @scheme[id], and places the values into the
locations. It then evaluates the @scheme[body]s, in which the
@scheme[id]s are bound. The last @scheme[body] expression is in
tail position with respect to the @scheme[let] form. The @scheme[id]s
must be distinct according to @scheme[bound-identifier=?].

@examples[
(let ([x 5]) x)
(let ([x 5])
  (let ([x 2]
        [y x])
    (list y x)))
]

The second form evaluates the @scheme[init-expr]s; the resulting
values become arguments in an application of a procedure
@scheme[(lambda (id ...) body ...+)], where @scheme[proc-id] is bound
within the @scheme[body]s to the procedure itself.}

@examples[
(let fac ([n 10])
  (if (zero? n)
      1
      (* n (fac (sub1 n)))))
]

@defform[(let* ([id val-expr] ...) body ...+)]{

Similar to @scheme[let], but evaluates the @scheme[val-expr]s one by
one, creating a location for each @scheme[id] as soon as the value is
available. The @scheme[id]s are bound in the remaining @scheme[val-expr]s
as well as the @scheme[body]s, and the @scheme[id]s need not be
distinct; later bindings shadow earlier bindings.

@examples[
(let ([x 1]
      [y (+ x 1)])
  (list y x))
]}

@defform[(letrec ([id val-expr] ...) body ...+)]{

Similar to @scheme[let], but the locations for all @scheme[id]s are
created first and filled with @|undefined-const|, and all
@scheme[id]s are bound in all @scheme[val-expr]s as well as the
@scheme[body]s. The @scheme[id]s must be distinct according to
@scheme[bound-identifier=?].

@examples[
(letrec ([is-even? (lambda (n)
                     (or (zero? n)
                         (is-odd? (sub1 n))))]
         [is-odd? (lambda (n)
                    (or (= n 1)
                        (is-even? (sub1 n))))])
  (is-odd? 11))
]}

@defform[(let-values ([(id ...) val-expr] ...) body ...+)]{ Like
@scheme[let], except that each @scheme[val-expr] must produce as many
values as corresponding @scheme[id]s, otherwise the
@exnraise[exn:fail:contract]. A separate location is created for each
@scheme[id], all of which are bound in the @scheme[body]s.

@examples[
(let-values ([(x y) (quotient/remainder 10 3)])
  (list y x))
]}

@defform[(let*-values ([(id ...) val-expr] ...) body ...+)]{ Like
@scheme[let*], except that each @scheme[val-expr] must produce as many
values as corresponding @scheme[id]s. A separate location is created
for each @scheme[id], all of which are bound in the later
@scheme[val-expr]s and in the @scheme[body]s.

@examples[
(let*-values ([(x y) (quotient/remainder 10 3)]
              [(z) (list y x)])
  z)
]}

@defform[(letrec-values ([(id ...) val-expr] ...) body ...+)]{ Like
@scheme[letrec], except that each @scheme[val-expr] must produce as
many values as corresponding @scheme[id]s. A separate location is
created for each @scheme[id], all of which are initialized to
@|undefined-const| and bound in all @scheme[val-expr]s
and in the @scheme[body]s.

@examples[
(letrec-values ([(is-even? is-odd?)
                 (values
                   (lambda (n)
                     (or (zero? n)
                         (is-odd? (sub1 n))))
                   (lambda (n)
                     (or (= n 1)
                         (is-even? (sub1 n)))))])
  (is-odd? 11))
]}

@;------------------------------------------------------------------------
@section[#:tag "mz:if"]{Conditionals: @scheme[if]}

@defform[(if test-expr then-expr else-expr)]{

Evaluates @scheme[test-expr]. If it produces any value other than
@scheme[#f], then @scheme[then-expr] is evaluated, and its results are
the result for the @scheme[if] form. Otherwise, @scheme[else-expr] is
evaluated, and its results are the result for the @scheme[if]
form. The @scheme[then-expr] and @scheme[else-expr] are in tail
position with respect to the @scheme[if] form.

@examples[
(if (positive? -5) (error "doesn't get here") 2)
(if (positive? 5) 1 (error "doesn't get here"))
]}

@;------------------------------------------------------------------------
@section[#:tag "mz:define"]{Definitions: @scheme[define] and @scheme[define-values]}

@defform*/subs[[(define id expr)
                (define (head args) body ...+)]
                ([head id
                       (head args)]
                 [args (code:line arg ...)
                       (code:line arg ... #, @schemeparenfont{.} rest-id)]
                 [arg arg-id
                      [arg-id default-expr]
                      (code:line keyword arg-id)
                      (code:line keyword [arg-id default-expr])])]{

The first form binds @scheme[id] to the result of @scheme[expr], and
the second form binds @scheme[id] to a procedure. In the second case,
the generation procedure is @scheme[(#,cvt (head args) body ...+)],
using the @|cvt| meta-function defined as follows:

@schemeblock[
(#,cvt (id . _gen-formals) . _datum)   = (lambda _gen-formals . _datum)
(#,cvt (head . _gen-formals) . _datum) = (lambda _gen-formals expr) 
                                         #, @elem{if} (#,cvt head . _datum) = expr
]

At the top level, the top-level binding @scheme[id] is created after
evaluating @scheme[expr], if it does not exist already, and the
top-level mapping of @scheme[id] (see @secref["mz:namespace"]) is set
to the binding at the same time.

@defexamples[
(define x 10)
x
]
@def+int[
(define (f x)
  (+ x 1))
(f 10)
]

@def+int[
(define ((f x) [y 20])
  (+ x y))
((f 10) 30)
((f 10))
]
}

@defform[(define-values (id ...) expr)]{

Evaluates the @scheme[expr], and binds the results to the
@scheme[id]s, in order, if the number of results matches the number of
@scheme[id]s; if @scheme[expr] produces a different number of results,
the @exnraise[exn:fail:contract].

At the top level, the top-level binding for each @scheme[id] is
created after evaluating @scheme[expr], if it does not exist already,
and the top-level mapping of each @scheme[id] (see
@secref["mz:namespace"]) is set to the binding at the same time.

@defexamples[
(define-values () (values))
(define-values (x y z) (values 1 2 3))
z
]
}

@;------------------------------------------------------------------------
@section{Sequencing: @scheme[begin] and @scheme[begin0]}

@defform*[[(begin form ...)
           (begin expr ...+)]]{

The first form applies when @scheme[begin] appears at the top level,
at module level, or in an internal-definition position (before any
expression in the internal-definition sequence). In that case, the
@scheme[begin] form is equivalent to splicing the @scheme[form]s into
the enclosing context.

The second form applies for @scheme[begin] in an expression position.
In that case, the @scheme[expr]s are evaluated in order, and the
results are ignored for all but the last @scheme[expr]. The last
@scheme[expr] is in tail position with respect to the @scheme[begin]
form.

@examples[
(begin
  (define x 10)
  x)
(+ 1 (begin 
       (printf "hi\n")
       2))
(let-values ([(x y) (begin
                      (values 1 2 3)
                      (values 1 2))])
 (list x y))
]}

@defform[(begin0 expr body ...+)]{

Evaluates the @scheme[expr], then evaluates the @scheme[body]s,
ignoring the @scheme[body] results. The results of the @scheme[expr]
are the results of the @scheme[begin0] form, but the @scheme[expr] is
in tail position only if no @scheme[body]s are present.



@examples[
(begin0
  (values 1 2)
  (printf "hi\n"))
]}