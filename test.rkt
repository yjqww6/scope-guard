#lang racket
(module+ test
  (require "main.rkt" rackunit racket/list)

  (define-syntax-rule (push! var val)
    (set! var (cons val var)))

  (define-syntax-rule (test-common with-)
    (test-begin
     
     (check-equal?
      (let ([v '()])
        (with- defer
          (push! v 0)
          (defer (push! v 1))
          (push! v 2)
          (defer (push! v 3))
          (push! v 4)
          (reverse v)))
      '(0 2 4))
     
     (check-equal?
      (let ([v '()])
        (let/ec k
          (with- defer
            (push! v 0)
            (defer (push! v 1))
            (push! v 2)
            (defer (push! v 3))
            (k (reverse v))
            (push! v 4)
            (reverse v))))
      '(0 2))

     (check-equal?
      (let ([v '()])
        (with- defer
          (push! v 0)
          (defer (push! v 1))
          (push! v 2)
          (defer (push! v 3))
          (push! v 4))
        
        (reverse v))
      '(0 2 4 3 1))

     (check-equal?
      (let ([v '()])
        (let/ec k
          (with- defer
            (push! v 0)
            (defer (push! v 1))
            (push! v 2)
            (defer (push! v 3))
            (k)
            (push! v 4)
            (reverse v)))
        
        (reverse v))
      '(0 2 3 1))

     (check-equal?
      (let ([v '()])
        (let/ec k
          (call-with-exception-handler
           (λ (e) (k (reverse v)))
           (λ ()
             (with- defer
               (push! v 0)
               (defer (push! v 1))
               (push! v 2)
               (defer (push! v 3))
               (error 'test)
               (push! v 4)
               (reverse v)))))
        
        (reverse v))
      '(0 2 3 1))

     (check-exn
      exn:fail:contract:continuation?
      (λ ()
        (let ([k #f])
          (with- defer
            (let/cc cc
              (set! k cc))
            (void))
          (k))))

     (check-not-exn
      (λ ()
        (let ([k #f])
          (with- defer #:barrier? #f
            (let/cc cc
              (set! k cc))
            (void))
          (let ([o k])
            (when k
              (set! k #f)
              (o))))))

     (check-equal?
      (let ([v '()])
        (with- defer #:handle-exception-only? #t
          (push! v 0)
          (defer (push! v 1))
          (push! v 2)
          (defer (push! v 3))
          (push! v 4))
        (reverse v))
      '(0 2 4 3 1))
     
     (check-equal?
      (let ([v '()])
        (let/ec k
          (with- defer #:handle-exception-only? #t
            (push! v 0)
            (defer (push! v 1))
            (push! v 2)
            (defer (push! v 3))
            (k (reverse v))
            (push! v 4))
          (reverse v)))
      '(0 2))
     
     (check-equal?
      (let ([v '()])
        (let/ec k
          (call-with-exception-handler
           (λ (e) (k))
           (λ ()
             (with- defer #:handle-exception-only? #t
               (push! v 0)
               (defer (push! v 1))
               (push! v 2)
               (defer (push! v 3))
               (error 'test-exit-via-exception)
               (push! v 4)
               (reverse v)))))
        
        (reverse v))
      '(0 2 3 1))

     (check-equal?
      (let ([v #f])
        (cons
         (with- defer
           (define-syntax-rule (def x)
             (define x 1))
           (define-syntax-rule (d x)
             (defer x))
           (def x)
           (d (set! v x))
           x)
         v))
      '(1 . 1))

     (check-equal?
      (with- defer
        (define x 1)
        (defer x)
        x)
      1)
     ))

  (test-common with-defer)
  (test-common with-scope-guard)

  (test-begin
   
   (check-equal?
    (let ([v '()])
      (with-defer defer
        (for ([i (in-range 10)])
          (defer (push! v i))))
      (reverse (reverse v)))
    (range 10))
  
   (check-exn
    exn:fail:syntax?
    (λ ()
      (expand
       #'(let ([v '()])
           (with-scope-guard guard
             (for ([i (in-range 10)])
               (guard (push! v i))))
           (reverse (reverse v))))))))
