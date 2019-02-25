#lang scribble/manual
@require[scribble/example]
@require[@for-label[scope-guard
                    racket/base]]

@title{scope-guard}
@author{yjqww6}

A library provides convenient ways for scoped cleanups.

@defmodule[scope-guard]

@defform[(with-defer defer-id options ... body ...+)
         #:grammar [(options
                     (code:line #:handle-exception-only? boolean)
                     (code:line #:barrier? boolean))]]

Evaluates each @italic{body}. If @racket[(defer-id expr ...+)] is encountered,
it will be evaluted when leaving this dynamic extent (in a reverse order).

If @racket[#:handle-exception-only?](which defaults to @racket[#f]) is provided with @racket[#t],
escape via continuation will not triggers the defers.

If @racket[#:barrier?](which defaults to @racket[#t]) is provided with @racket[#f],
the block will not be guarded by a continuation barrier.

@(define my-evaluator (make-base-eval))

@examples[#:eval my-evaluator
          (require scope-guard)
          (define-syntax-rule (push! var val)
            (set! var (cons val var)))
          (let ([v '()])
            (with-defer defer
              (push! v 0)
              (defer (push! v 1))
              (push! v 2)
              (defer (push! v 3))
              (push! v 4))
            (reverse v))
          (let ([v '()])
            (let/ec k
              (with-defer defer
                (push! v 0)
                (defer (push! v 1))
                (push! v 2)
                (defer (push! v 3))
                (k)
                (push! v 4)
                (reverse v)))
            (reverse v))
          (let ([v '()])
            (with-defer defer
              (for ([i (in-range 10)])
                (defer (push! v i))))
            (reverse (reverse v)))]

@defform[(with-scope-guard guard-id options ... body ...+)
         #:grammar [(options
                     (code:line #:handle-exception-only? boolean)
                     (code:line #:barrier? boolean))]]

Same as @racket[with-defer], but @racket[(guard-id expr ...+)] is only available
in the immediate definition context, which is slightly more efficient.

@examples[#:eval my-evaluator
          (eval:error
           (let ([v '()])
             (with-scope-guard guard
               (for ([i (in-range 10)])
                 (guard (push! v i))))
             (reverse (reverse v))))]